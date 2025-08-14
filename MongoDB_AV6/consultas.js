// Comandos usados: 'USE'
use("gerenciamento_times_esportivos");

// Comandos usados: 'AGGREGATE', 'GROUP', 'SUM, 'SORT'
// Calcula o saldo de gols de todos os campeonatos e os ordena de forma decrescente
db.Campeonatos.aggregate([
    {
        $unwind: "$partidas",
    },
    {
        $group: {
            _id: "$_id",
            nome: { $first: "$nome" },
            totalGolsEquipe: { $sum: "$partidas.gols_equipe" },
            totalGolsAdversario: { $sum: "$partidas.gols_adversario" },
        },
    },
    {
        $addFields: {
            saldoGols: {
                $subtract: ["$totalGolsEquipe", "$totalGolsAdversario"],
            },
        },
    },
    { $sort: { saldoGols: -1 } },
]);

// Comandos usados: 'SIZE', 'MATCH', 'PROJECT', 'GTE', 'LOOKUP'
// Seleciona todos os jogadores com no minímo 3 lesões e exibe o nome do jogador,
// tempo total afastado por lesões e também o tempo médio por cada lesão
db.Jogadores.aggregate([
    {
        $match: {
            $expr: { $gte: [{ $size: "$lesoes" }, 3] },
        },
    },
    {
        $lookup: {
            from: "Pessoas",
            localField: "_id",
            foreignField: "_id",
            as: "dados_pessoa",
        },
    },
    {
        $unwind: "$lesoes",
    },

    {
        $addFields: {
            dias_afastado: {
                $divide: [
                    {
                        $subtract: ["$lesoes.data_retorno", "$lesoes.data_lesionamento"],
                    },
                    1000 * 60 * 60 * 24,
                ],
            },
        },
    },

    {
        $group: {
            _id: "$_id",
            nome: { $first: { $arrayElemAt: ["$dados_pessoa.nome", 0] } },
            tempo_medio_afastado_dias: { $avg: "$dias_afastado" },
            tempo_total_afastado_dias: { $sum: "$dias_afastado" },
            total_lesoes: { $sum: 1 },
        },
    },

    {
        $project: {
            _id: 0,
            nome: 1,
            tempo_medio_afastado_dias: { $round: ["$tempo_medio_afastado_dias", 1] },
            tempo_total_afastado_dias: { $round: ["$tempo_total_afastado_dias", 1] },
            total_lesoes: 1,
        },
    },

    {
        $sort: { tempo_total_afastado_dias: -1 },
    },
]);

// Comandos usados: "PRETTY", "FIND"
// Listar todos os sócios de forma legível
db.Socios.find({}).pretty();

// Comandos usados: "COUNTDOCUMENTS"
// Mostra o total de jogadores que têm o contrato ativo
db.Jogadores.countDocuments({
    contratos: {
        $elemMatch: {
            status: "Ativo",
            clube: null,
        },
    },
});

// Comandos usados: "MAX"
// Seleciona o salário mais alto entre os treinadores que estão com o contrato ativo
db.Treinadores.aggregate([
    {
        $match: {
            contratos: {
                $elemMatch: {
                    status: "Ativo",
                    clube: null,
                },
            },
        },
    },
    { $unwind: "$contratos" },
    {
        $match: {
            "contratos.status": "Ativo",
            "contratos.clube": null,
        },
    },
    {
        $group: {
            _id: null,
            maiorPagamento: { $max: "$contratos.pagamento_mensal" },
        },
    },
    {
        $project: {
            _id: 0,
            maiorPagamento: 1,
        },
    },
]);

// Comandos usados: "EXISTS"
// Lista os funcionários que já não são mais empregados (tem data de fim de contrato)
db.Funcionarios.find({ fim_contrato: { $exists: true, $ne: null } });

// Comandos usados: "LIMIT"
// Lista os 5 primeiros jogadores em ordem decrescente pela altura
db.Jogadores.aggregate([
    {
        $lookup: {
            from: "Pessoas",
            localField: "_id",
            foreignField: "_id",
            as: "dados_pessoa",
        },
    },
    {
        $project: {
            nome: { $arrayElemAt: ["$dados_pessoa.nome", 0] },
            altura: 1,
            _id: 0,
        },
    },
    { $sort: { altura: -1 } },
    { $limit: 5 },
]);

// Comandos usados: '$WHERE'
// Lista pessoas que tem mais email registrados do que telefones
db.Pessoas.find({
    $where: "this.emails.length > this.telefones.length",
});

// Comandos usados: 'FILTER', 'COND'
// Lista os jogadores com todas os cartões vermelhos que receberam
db.Jogadores.aggregate([
    {
        $lookup: {
            from: "Pessoas",
            localField: "_id",
            foreignField: "_id",
            as: "dados_pessoa",
        },
    },
    {
        $project: {
            nome: { $arrayElemAt: ["$dados_pessoa.nome", 0] },
            _id: 0,
            faltas_graves: {
                $filter: {
                    input: "$punicoes",
                    as: "punicao",
                    cond: { $eq: ["$$punicao.tipo", "Cartão Vermelho"] },
                },
            },
        },
    },
    {
        $addFields: {
            total_faltas_graves: { $size: "$faltas_graves" },
        },
    },
    { $sort: { total_faltas_graves: -1 } },
]);

// Comandos usados: 'ALL', 'FINDONE'
// Lista as partidas de campeonatos onde dois jogadores aleatórios participaram
// Indica os nomes destes jogadores enfaticamente
var jogadores_ids = db.Jogadores.aggregate([{ $sample: { size: 2 } }, { $project: { _id: 1 } }])
    .toArray()
    .map((j) => j._id);

db.Campeonatos.aggregate([
    { $unwind: "$partidas" },
    { $match: { "partidas.jogadores": { $all: jogadores_ids } } },
    {
        $project: {
            _id: 0,
            campeonato: "$nome",
            partida_id: "$partidas._id",
            data: "$partidas.data",
            adversario_id: "$partidas.adversario",
            gols_nosso_time: "$partidas.gols_equipe",
            gols_adversario: "$partidas.gols_adversario",
            jogadores: "$partidas.jogadores",
        },
    },
])
    .toArray()
    .map(function (partida) {
        return {
            campeonato: partida.campeonato,
            partida_id: partida.partida_id,
            data: partida.data,
            clube_adversario: db.ClubesAdversarios.findOne({ _id: partida.adversario_id }).nome,
            gols_nosso_time: partida.gols_nosso_time,
            gols_adversario: partida.gols_adversario,
            jogadores: partida.jogadores.map((j) => {
                var jogador = db.Pessoas.findOne({ _id: j });
                if (jogadores_ids.includes(jogador._id)) return ">>> " + jogador.nome.toUpperCase() + " <<<";
                return jogador.nome;
            }),
        };
    });

// Comandos usados: 'MAPREDUCE', 'FUNCTION'
// Calcula o total de espectadores em partidas que nosso clube jogou em cada campeonato
var mapEspectadores = function () {
    if (this.partidas) {
        this.partidas.forEach(function (partida) {
            emit(this["_id"], partida["espectadores"]);
        }, this);
    }
};

var reduceEspectadores = function (key, values) {
    return Array.sum(values);
};

db.Campeonatos.mapReduce(mapEspectadores, reduceEspectadores, { out: "espectadores_por_campeonato" });
db.espectadores_por_campeonato.find().map(function (mapreduce) {
    return {
        campeonato: db.Campeonatos.findOne({ _id: mapreduce._id }).nome,
        total_espectadores: mapreduce.value,
    };
});

// Comandos usados: 'SET', 'UPDATE' (UPDATEONE)
// Atualiza salário de funcionários baseado na função e tempo de serviço
// Funcionários de segurança com mais de 5 anos recebem aumento de 15%
db.Funcionarios.aggregate([
    {
        $match: {
            funcao: "Segurança",
            contrado_em: { $lt: new Date(new Date().getFullYear() - 5, 0, 1) },
        },
    },
    {
        $addFields: {
            novo_salario: { $multiply: ["$salario", 1.15] },
        },
    },
]).forEach(function (funcionario) {
    db.Funcionarios.updateOne({ _id: funcionario._id }, { $set: { salario: funcionario.novo_salario } });
});

// Comandos usados: 'TEXT', 'SEARCH'
// Busca por pessoas usando índice de texto composto
db.Pessoas.createIndex(
    {
        nome: "text",
        nacionalidade: "text",
    },
    {
        weights: { nome: 10, nacionalidade: 5 },
        name: "busca_pessoa_completa",
    }
);

// Busca pessoas brasileiras cujo nome contenha palavras específicas
db.Pessoas.aggregate([
    {
        $match: {
            $and: [{ $text: { $search: "Silva Santos Oliveira" } }, { nacionalidade: "Brasil" }],
        },
    },
    {
        $addFields: {
            score: { $meta: "textScore" },
            idade: {
                $floor: {
                    $divide: [{ $subtract: [new Date(), "$data_nascimento"] }, 1000 * 60 * 60 * 24 * 365.25],
                },
            },
        },
    },
    {
        $sort: { score: { $meta: "textScore" }, idade: -1 },
    },
    {
        $project: {
            nome: 1,
            nacionalidade: 1,
            idade: 1,
            score: 1,
            _id: 0,
        },
    },
]);

// Comandos usados: 'UPDATEMANY'
// Gestão de contratos baseada em performance dos jogadores
// Encerra o contrato de jogadores com baixa performance imediatamente
// Extende o contrato de jogadores com alta performance por mais 2 anos
db.Jogadores.aggregate([
    {
        $match: {
            "contratos.clube": null,
            "contratos.status": "Ativo",
        },
    },
    {
        $addFields: {
            total_lesoes: { $size: "$lesoes" },
            total_punicoes: { $size: "$punicoes" },
            performance_score: {
                $subtract: [
                    100,
                    {
                        $add: [{ $multiply: [{ $size: "$lesoes" }, 5] }, { $multiply: [{ $size: "$punicoes" }, 10] }],
                    },
                ],
            },
        },
    },
]).forEach(function (jogador) {
    if (jogador.performance_score < 70) {
        // Encerra contrato imediatamente para jogadores com performance abaixo de 70
        db.Jogadores.updateMany(
            {
                _id: jogador._id,
                "contratos.clube": null,
                "contratos.status": "Ativo",
            },
            {
                $set: {
                    "contratos.$.status": "Encerrado",
                    "contratos.$.data_fim": new Date(),
                },
            }
        );
    } else if (jogador.performance_score >= 70) {
        // Extende contrato por 2 anos para jogadores com performance 70 ou maior
        db.Jogadores.updateMany(
            {
                _id: jogador._id,
                "contratos.clube": null,
                "contratos.status": "Ativo",
            },
            {
                $set: {
                    "contratos.$.data_fim": new Date(
                        jogador.contratos[0].data_fim.setFullYear(jogador.contratos[0].data_fim.getFullYear() + 2)
                    ),
                },
            }
        );
    }
});

// Comandos usados: 'RENAMECOLLECTION'
// Renomeia a coleção de "Patrocinios" para "Patrocinadores"
// E lista os patrocinadores com pagamento mensal superior a 6 milhões
db.Patrocinios.renameCollection("Patrocinadores");
db.Patrocinadores.find({ $where: "this.pagamento_mensal > 6000000" });

// Comandos usados: 'ADDTOSET'
// Dá para cada funcionário um email do clube baseado no nome
var gerar_email = function (nome) {
    return nome.toLowerCase().replace(/\s+/g, ".") + "@futebolclube.com.br";
};
db.Pessoas.find({ $where: "this.tipo == 'Funcionário' && this.fim_contrato == null" }).forEach(function (pessoa) {
    var email = gerar_email(pessoa.nome);

    db.Pessoas.updateOne({ _id: pessoa._id }, { $addToSet: { emails: email } });
});

// Comandos usados: 'SAVE' (INSERTONE)
// Adiciona um rival digno ao nosso clube
db.ClubesAdversarios.insertOne({
    _id: "-1",
    nome: "조선민주주의인민공화국 축구협회",
    sigla: "KDPR",
    pais: "Coréia do Norte",
});
