#Include "Protheus.ch" 
#Include "TopConn.ch"
#include "FWMVCDEF.CH" 
#include "parmtype.ch"
 
/*/{Protheus.doc} OMSA010
Exemplo de Ponto de Entrada em MVC - Tabela de Preço
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

	//Se tiver parâmetros
	If aParam != Nil 
 
		//Pega informações dos parâmetros
		oObj := aParam[1] 
		cIdPonto := aParam[2] 
		cIdModel := aParam[3] 
		nOpc     := oObj:GetOperation()

		//Valida a abertura da tela
		If cIdPonto == "MODELVLDACTIVE"
			xRet := .T. 
 
		//Pré configurações do Modelo de Dados
		ElseIf cIdPonto == "MODELPRE"
			xRet := .T. 
 
		//Pré configurações do Formulário de Dados
		ElseIf cIdPonto == "FORMPRE"
			xRet := .T. 
 
		//Adição de opções no Ações Relacionadas dentro da tela
		ElseIf cIdPonto == "BUTTONBAR"
			xRet := {}
 
		//Pós configurações do Formulário
		ElseIf cIdPonto == "FORMPOS"
			xRet := .T. 
 
		//Validação ao clicar no Botão Confirmar
		ElseIf cIdPonto == "MODELPOS"
			xRet := .T. 
 
		//Pré validações do Commit
		ElseIf cIdPonto == "FORMCOMMITTTSPRE"

		//Pós validações do Commit
		ElseIf cIdPonto == "FORMCOMMITTTSPOS"

		//Commit das operações (antes da gravação)
		ElseIf cIdPonto == "MODELCOMMITTTS"
 
		//Commit das operações (após a gravação)
		ElseIf cIdPonto == "MODELCOMMITNTTS"

			oAPIPreco := Telecontrol.Integracao.Preco.TTLCPreco():New()
			if nOpc == MODEL_OPERATION_INSERT // inclusão
				if isBlind()
					oAPIPreco:Cadastra()
				else
					FwMsgRun(NIL, {|| lOk := oAPIPreco:Cadastra()}, "Telecontrol", "Gravando informações...")
					if !lOk
						FWAlertWarning("Não foi possível efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
					endif
				endif
			elseif nOpc == MODEL_OPERATION_UPDATE // alteração	
				// consulta o preço no telecontrol
				cCodRet := '500'
				if !oAPIPreco:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // se não existia, então inclui
					if isBlind()
						oAPIPreco:Cadastra()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPreco:Cadastra()}, "Telecontrol", "Gravando informações...")
						if !lOk
							FWAlertWarning("Não foi possível efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				elseif (cCodRet == '200') // se já existia, então altera
					if isBlind()
						oAPIPreco:Altera()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPreco:Altera()}, "Telecontrol", "Atualizando informações...")
						if !lOk
							FWAlertWarning("Não foi possível efetuar a alteração do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				endif
			endif
			FWFreeObj(oAPIPreco)

		EndIf 
	EndIf 
Return xRet
