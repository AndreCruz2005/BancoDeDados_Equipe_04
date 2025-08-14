// Comandos usados: 'USE'
use("gerenciamento_times_esportivos");

// Comandos usados: 'AGGREGATE', 'GROUP', 'SUM, 'SORT'
// Calcula o saldo de gols de todos os campeonatos e os ordena de forma decrescente
const saldoGols = db.Campeonatos.aggregate([
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
console.log("Saldo de gols de todos os campeonatos:\n", saldoGols.toArray());

// Comandos usados: 'SIZE', 'MATCH', 'PROJECT', 'GTE', 'LOOKUP'
// Seleciona todos os jogadores com no minímo 3 lesões e exibe o nome do jogador,
// tempo total afastado por lesões e também o tempo médio por cada lesão
const jogadoresComMuitasLesoes = db.Jogadores.aggregate([
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
console.log(res);

// Listar todos os sócios de forma legível
// Comandos usados: "PRETTY", "FIND"
db.Socios.find({}).pretty();

// Mostra o total de jogadores que têm o contrato ativo
// Comandos usados: "COUNTDOCUMENTS"
const totalJogadoresAtivos = db.Contratos.countDocuments({
    tipo: "Jogador",
    status: "Ativo"
});
console.log(`No total, temos ${totalJogadoresAtivos} de jogadores ativos no momento`);

// Encontra o treinador com o maior salário
// Comandos usados: "AGREGGATE", "MAX"
db.Contratos.aggregate([
    { $match: {tipo: "Treinador"} },
    { $group: {_id: null, maiorSalario: { $max: "$salario_mensal" } } }
]);

// Lista as pessoas que têm endereços registrados e não nulos
// Comandos usados: "AGREGGATE", "EXISTS"
db.Pessoas.find({ $endereco: { $exists: true, $ne: null } })

// Lista os 5 primeiros jogares em ordem decrescente pela altura
// Comandos usados: "SORT", "FIND", "LIMIT"
db.Jogadores.find({}, { nome: 1, idade: 1, _id: 0 })
    .sort({altura: -1})
    .limit(5)

// Lista pessoas que tem mais email registrados do que telefones
// Comandos usados: 'FIND', '$WHERE'
db.Pessoas.find({
  $where: "this.emails.length > this.telefones.length"
});

