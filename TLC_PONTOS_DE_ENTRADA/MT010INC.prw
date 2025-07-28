#include "totvs.ch"
#include "parmtype.ch"

USER FUNCTION MT010INC()
Local oAPIIntegr as object
Local cMVRProd := GetMV('TI_TLCPROD',.F.,"SB1->B1_TIPO == 'PA'") as character // regra para identificar um produto
Local cMVRPeca := GetMV('TI_TLCPECA',.F.,"SB1->B1_TIPO == 'PI'") as character // regra para identificar uma pe�a
Local lOk as logical

	// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	//
	// PRECISO DA DEFINI��O DE O QUE DEVE SER GRAVADO COMO PE�A
	// E O QUE DEVE SER GRAVADO COMO PRODUTO
	//
	// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	if INCLUI .AND. ( &(cMVRProd) .OR. &(cMVRPeca) ) // inclus�o
		if &(cMVRProd)
			oAPIIntegr := Telecontrol.Integracao.Produto.TTLCProduto():New()
		else
			oAPIIntegr := Telecontrol.Integracao.Peca.TTLCPeca():New()
		endif

		if isBlind()
			oAPIIntegr:Cadastra()
		else
			FwMsgRun(NIL, {|| lOk := oAPIIntegr:Cadastra()}, "Telecontrol", "Gravando informa��es...")
			if !lOk
				FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
			endif
		endif

	    FWFreeObj(@oAPIIntegr)
	endif

RETURN
