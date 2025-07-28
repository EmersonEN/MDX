#include "totvs.ch"
#include "parmtype.ch"

USER FUNCTION MT010ALT()
Local oAPIIntegr as object
Local cCodRet as character
Local cMVRProd := GetMV('TI_TLCPROD',.F.,"SB1->B1_TIPO == 'PA'") as character // regra para identificar um produto
Local cMVRPeca := GetMV('TI_TLCPECA',.F.,"SB1->B1_TIPO == 'PI'") as character // regra para identificar uma peça
Local lOk as logical

	if ALTERA .AND. ( &(cMVRProd) .OR. &(cMVRPeca) ) // alteraçãO
		if &(cMVRProd)
			oAPIIntegr := Telecontrol.Integracao.Produto.TTLCProduto():New()
		else
			oAPIIntegr := Telecontrol.Integracao.Peca.TTLCPeca():New()
		endif

		// consulta o cliente no telecontrol
		cCodRet := '500'
		if !oAPIIntegr:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // não existia, então inclui
			if isBlind()
				oAPIIntegr:Cadastra()
			else
				FwMsgRun(NIL, {|| lOk := oAPIIntegr:Cadastra()}, "Telecontrol", "Gravando informações...")
				if !lOk
					FWAlertWarning("Não foi possível efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
				endif
			endif
		elseif (cCodRet == '200') // já existia, então altera
			if isBlind()
				oAPIIntegr:Altera()
			else
				FwMsgRun(NIL, {|| lOk := oAPIIntegr:Altera()}, "Telecontrol", "Atualizando informações...")
				if !lOk
					FWAlertWarning("Não foi possível efetuar a alteração do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
				endif
			endif
		endif

	    FWFreeObj(@oAPIIntegr)
	endif

RETURN
