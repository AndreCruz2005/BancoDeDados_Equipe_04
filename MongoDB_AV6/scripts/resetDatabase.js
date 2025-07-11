import db from "../config/db.js";

async function resetDatabase() {
    try {
        await db.connection.asPromise();

        const collections = await db.connection.db.collections();

        for (let collection of collections) {
            await collection.drop();
            console.log(`Coleção ${collection.collectionName} deletada.`);
        }

        console.log("Banco de dados resetado com sucesso (todas as coleções foram apagadas).");
    } catch (err) {
        if (err.message === 'ns not found') {
            console.warn("Alguma coleção já estava vazia ou não existia.");
        } else {
            console.error("Erro ao resetar o banco:", err.message);
        }
    } finally {
        await db.disconnect();
    }
}

resetDatabase();