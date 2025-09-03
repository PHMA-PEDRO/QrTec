// functions/index.js

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

// A definição da região agora é feita aqui
const REGIAO = "southamerica-east1"; // São Paulo

exports.notificarAdminPorEmail = onDocumentCreated(
  {
    document: "movimentacoes/{movId}",
    region: REGIAO,
  },
  async (event) => {
    const dadosMovimentacao = event.data.data();
    const tagEquipamento = dadosMovimentacao.tagEquipamento;
    logger.log(`Nova movimentação detectada para a TAG: ${tagEquipamento}`);

    try {
      const equipDoc = await db.collection("equipamentos").doc(tagEquipamento).get();
      if (!equipDoc.exists) {
        logger.log(`Equipamento ${tagEquipamento} não encontrado.`);
        return null;
      }
      const tipoEquipamento = equipDoc.data().tipo_equipamento;
      const nomeEquipamento = equipDoc.data().nome;

      if (!tipoEquipamento) {
        logger.log(`Equipamento ${tagEquipamento} não possui tipo definido.`);
        return null;
      }
      
      const adminsSnapshot = await db.collection("usuarios")
        .where("funcao", "==", "admin")
        .where("notificacao_tipos", "array-contains", tipoEquipamento)
        .get();

      if (adminsSnapshot.empty) {
        logger.log(`Nenhum admin inscrito para notificações do tipo '${tipoEquipamento}'.`);
        return null;
      }

      const emailsPromises = adminsSnapshot.docs.map(adminDoc => {
        const adminData = adminDoc.data();
        const email = adminData.email;

        if (email) {
          logger.log(`Criando pedido de e-mail para ${email}`);
          return db.collection("emails").add({
            to: [email],
            message: {
              subject: `Alerta de Movimentação: ${tagEquipamento}`,
              html: `
                <h1>Alerta de Movimentação de Equipamento</h1>
                <p>O equipamento <strong>${tagEquipamento}</strong> (${nomeEquipamento}) do tipo <strong>${tipoEquipamento}</strong> foi movimentado.</p>
                <ul>
                  <li><strong>Ação:</strong> ${dadosMovimentacao.tipo}</li>
                  <li><strong>Responsável:</strong> ${dadosMovimentacao.responsavel}</li>
                  <li><strong>Projeto:</strong> ${dadosMovimentacao.nomeProjeto}</li>
                  <li><strong>Local Aproximado:</strong> ${dadosMovimentacao.localizacao}</li>
                </ul>
                <p>Para mais detalhes, acesse o painel de administrador.</p>
              `,
            },
          });
        }
        return null;
      });

      return Promise.all(emailsPromises);

    } catch (error) {
      logger.error("Erro na função de notificação por e-mail:", error);
      return null;
    }
  });