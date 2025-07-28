#Include "Protheus.ch" 
#Include "TopConn.ch"
#include "FWMVCDEF.CH" 
#include "parmtype.ch"
 
/*/{Protheus.doc} OMSA010
Exemplo de Ponto de Entrada em MVC - Tabela de Pre�o
@author  
@since 21/06/2018
@version 1.0 
@type function 
@obs
/*/
User Function OMSA010() 
Local aParam     := PARAMIXB 
Local xRet       := .T. 
Local oObj       := Nil 
Local cIdPonto   := ""
Local cIdModel   := ""
Local oAPIPreco  as object
Local lOk        as logical

	//Se tiver par�metros
	If aParam != Nil 
 
		//Pega informa��es dos par�metros
		oObj := aParam[1] 
		cIdPonto := aParam[2] 
		cIdModel := aParam[3] 
		nOpc     := oObj:GetOperation()

		//Valida a abertura da tela
		If cIdPonto == "MODELVLDACTIVE"
			xRet := .T. 
 
		//Pr� configura��es do Modelo de Dados
		ElseIf cIdPonto == "MODELPRE"
			xRet := .T. 
 
		//Pr� configura��es do Formul�rio de Dados
		ElseIf cIdPonto == "FORMPRE"
			xRet := .T. 
 
		//Adi��o de op��es no A��es Relacionadas dentro da tela
		ElseIf cIdPonto == "BUTTONBAR"
			xRet := {}
 
		//P�s configura��es do Formul�rio
		ElseIf cIdPonto == "FORMPOS"
			xRet := .T. 
 
		//Valida��o ao clicar no Bot�o Confirmar
		ElseIf cIdPonto == "MODELPOS"
			xRet := .T. 
 
		//Pr� valida��es do Commit
		ElseIf cIdPonto == "FORMCOMMITTTSPRE"

		//P�s valida��es do Commit
		ElseIf cIdPonto == "FORMCOMMITTTSPOS"

		//Commit das opera��es (antes da grava��o)
		ElseIf cIdPonto == "MODELCOMMITTTS"
 
		//Commit das opera��es (ap�s a grava��o)
		ElseIf cIdPonto == "MODELCOMMITNTTS"

			oAPIPreco := Telecontrol.Integracao.Preco.TTLCPreco():New()
			if nOpc == MODEL_OPERATION_INSERT // inclus�o
				if isBlind()
					oAPIPreco:Cadastra()
				else
					FwMsgRun(NIL, {|| lOk := oAPIPreco:Cadastra()}, "Telecontrol", "Gravando informa��es...")
					if !lOk
						FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
					endif
				endif
			elseif nOpc == MODEL_OPERATION_UPDATE // altera��o	
				// consulta o pre�o no telecontrol
				cCodRet := '500'
				if !oAPIPreco:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // se n�o existia, ent�o inclui
					if isBlind()
						oAPIPreco:Cadastra()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPreco:Cadastra()}, "Telecontrol", "Gravando informa��es...")
						if !lOk
							FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				elseif (cCodRet == '200') // se j� existia, ent�o altera
					if isBlind()
						oAPIPreco:Altera()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPreco:Altera()}, "Telecontrol", "Atualizando informa��es...")
						if !lOk
							FWAlertWarning("N�o foi poss�vel efetuar a altera��o do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				endif
			endif
			FWFreeObj(oAPIPreco)

		EndIf 
	EndIf 
Return xRet
