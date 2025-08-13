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
