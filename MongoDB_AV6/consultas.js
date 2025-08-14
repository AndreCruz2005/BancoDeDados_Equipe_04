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

// Lista os funcionários que foram demitidos
// Comandos usados: "EXISTS"
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

// Comandos usados: 'MAPREDUCE', 'FUNCTION'
// Calcula o total de espectadores em partidas que nosso clube jogou em cada campeonato
var mapEspectadores = function () {
    if (this.partidas) {
        this.partidas.forEach(function (partida) {
            emit(this["nome"], partida["espectadores"]);
        }, this);
    }
};

var reduceEspectadores = function (key, values) {
    return Array.sum(values);
};

db.Campeonatos.mapReduce(mapEspectadores, reduceEspectadores, { out: "espectadores_por_campeonato" });
db.espectadores_por_campeonato.find();

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

// Comandos usados: 'ALL'
// Lista as partidas de campeonatos onde dois jogadores aleatórios participaram
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
            clube_adversario: "$partidas.adversario",
            gols_nosso_time: "$partidas.gols_equipe",
            gols_adversario: "$partidas.gols_adversario",
            jogadores: "$partidas.jogadores",
        },
    },
]);
