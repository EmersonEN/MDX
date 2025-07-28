#include "Protheus.ch"
#include "FWMVCDEF.CH" 
#include "parmtype.CH" 

//-------------------------------------------------------------------
/*/{Protheus.doc} CUSTOMERVENDOR()
Ponto de Entrada do Cadastro de Fornecedores (MVC)
@param      Não há
@return     Vários. Dependerá de qual PE está sendo executado.
@author     Compras
@version    12.1.17 / Superior
@since      Abr/2025
/*/
//-------------------------------------------------------------------
User Function CUSTOMERVENDOR()
 
Local aParam        := PARAMIXB
Local xRet          := .T.
Local lIsGrid       := .F.
Local cIDPonto      := ''
Local cIDModel      := ''
Local cIDForm       := ''
Local cEvento       := ''
Local cCampo        := ''
Local cConteudo     := ''
Local oObj          := NIL

Local oAPIPosto   as object
Local lOk         as logical

If aParam <> NIL

	oObj        := aParam[1]
	cIDPonto    := aParam[2]
	cIDModel    := aParam[3]
	lIsGrid     := (Len(aParam) > 3)
	nOpc        := oObj:GetOperation()

	If cIDPonto == 'FORMPRE'
 
		cEvento     := aParam[4]
		cCampo      := aParam[5]
		cConteudo   := If( ValType(aParam[6]) == 'C',;
						   "'" + aParam[6] + "'",;
						   If( ValType(aParam[6]) == 'N',;
							   AllTrim(Str(aParam[6])),;
							   If( ValType(aParam[6]) == 'D',;
								   DtoC(aParam[6]),;
								   If(ValType(aParam[4]) == 'L',;
									  If(aParam[4], '.T.', '.F.'),;
									  ''))))
		cIDForm     := oObj:GetID()
 
	ElseIf cIDPonto == 'FORMPOS'
 
		cIDForm     := oObj:GetID()
 
	ElseIf cIDPonto == 'FORMCOMMITTTSPRE' .OR. cIDPonto == 'FORMCOMMITTTSPOS'
 
		cConteudo   := If( ValType(aParam[4]) == 'L',;
						   If( aParam[4], '.T.', '.F.'),;
						   '')

	EndIf
 
	If cIDPonto == 'MODELVLDACTIVE'
/*
		Valida se o modelo do cadastro de fornecedores pode ou não ser exibido ao usuário
*/
	ElseIf cIDPonto == 'MODELPRE'
/*
	   Antes da alteração de qualquer campo do Modelo
*/
	ElseIf cIDPonto == 'FORMPRE'
/*
		Antes da alteração de qualquer campo do Formulário
*/
	ElseIf cIDPonto == 'BUTTONBAR'
/*
		Adicionando um botão na barra de botões da rotina
*/
	ElseIf cIDPonto == 'FORMPOS'
/*
		Chamada na validação final do formulário
*/
	ElseIf  cIDPonto == 'MODELPOS'
/*
		Chamada na validação total do modelo
*/
	ElseIf cIDPonto == 'FORMCOMMITTTSPRE'
/*
		Chamada antes da gravação da tabela do formulário
*/
	ElseIf cIDPonto == 'FORMCOMMITTTSPOS'
/*
		Chamada após a gravação da tabela do formulário
*/
	ElseIf cIDPonto == 'MODELCOMMITTTS'
/*
		Chamada após a gravação total do modelo e dentro da transação
*/
	ElseIf cIDPonto == 'MODELCOMMITNTTS'
/*
		Chamada após a gravação total do modelo e fora da transação
*/
		if !empty(oObj:GetModel('SA2MASTER'):GetValue('A2_TPOSTO'))
			oAPIPosto := Telecontrol.Integracao.Posto.TTLCPosto():New()
			if nOpc == MODEL_OPERATION_INSERT // inclusão
				if isBlind()
					oAPIPosto:Cadastra()
				else
					FwMsgRun(NIL, {|| lOk := oAPIPosto:Cadastra()}, "Telecontrol", "Gravando informações...")
					if !lOk
						FWAlertWarning("Não foi possível efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
					endif
				endif
			elseif nOpc == MODEL_OPERATION_UPDATE // alteração	
				// consulta o Posto no telecontrol
				cCodRet := '500'
				if !oAPIPosto:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // se não existia, então inclui
					if isBlind()
						oAPIPosto:Cadastra()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPosto:Cadastra()}, "Telecontrol", "Gravando informações...")
						if !lOk
							FWAlertWarning("Não foi possível efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				elseif (cCodRet == '200') // se já existia, então altera
					if isBlind()
						oAPIPosto:Altera()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPosto:Altera()}, "Telecontrol", "Atualizando informações...")
						if !lOk
							FWAlertWarning("Não foi possível efetuar a alteração do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				endif
			endif
			FWFreeObj(oAPIPosto)
		endif

	ElseIf cIDPonto == 'MODELCANCEL'
/*
		Chamada após o cancelamento da edição do cadastro de fornecedores
*/
	EndIf

EndIf
 
Return xRet

