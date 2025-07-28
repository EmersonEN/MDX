#include "totvs.ch"
#include "parmtype.ch"

USER FUNCTION MT010ALT()
Local oAPIIntegr as object
Local cCodRet as character
Local cMVRProd := GetMV('TI_TLCPROD',.F.,"SB1->B1_TIPO == 'PA'") as character // regra para identificar um produto
Local cMVRPeca := GetMV('TI_TLCPECA',.F.,"SB1->B1_TIPO == 'PI'") as character // regra para identificar uma pe�a
Local lOk as logical

	if ALTERA .AND. ( &(cMVRProd) .OR. &(cMVRPeca) ) // altera��O
		if &(cMVRProd)
			oAPIIntegr := Telecontrol.Integracao.Produto.TTLCProduto():New()
		else
			oAPIIntegr := Telecontrol.Integracao.Peca.TTLCPeca():New()
		endif

		// consulta o cliente no telecontrol
		cCodRet := '500'
		if !oAPIIntegr:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // n�o existia, ent�o inclui
			if isBlind()
				oAPIIntegr:Cadastra()
			else
				FwMsgRun(NIL, {|| lOk := oAPIIntegr:Cadastra()}, "Telecontrol", "Gravando informa��es...")
				if !lOk
					FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
				endif
			endif
		elseif (cCodRet == '200') // j� existia, ent�o altera
			if isBlind()
				oAPIIntegr:Altera()
			else
				FwMsgRun(NIL, {|| lOk := oAPIIntegr:Altera()}, "Telecontrol", "Atualizando informa��es...")
				if !lOk
					FWAlertWarning("N�o foi poss�vel efetuar a altera��o do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
				endif
			endif
		endif

	    FWFreeObj(@oAPIIntegr)
	endif

RETURN
