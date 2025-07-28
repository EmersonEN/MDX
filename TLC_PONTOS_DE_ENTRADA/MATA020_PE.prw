#include "Protheus.ch"
#include "FWMVCDEF.CH" 
#include "parmtype.CH" 

//-------------------------------------------------------------------
/*/{Protheus.doc} CUSTOMERVENDOR()
Ponto de Entrada do Cadastro de Fornecedores (MVC)
@param      N�o h�
@return     V�rios. Depender� de qual PE est� sendo executado.
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
		Valida se o modelo do cadastro de fornecedores pode ou n�o ser exibido ao usu�rio
*/
	ElseIf cIDPonto == 'MODELPRE'
/*
	   Antes da altera��o de qualquer campo do Modelo
*/
	ElseIf cIDPonto == 'FORMPRE'
/*
		Antes da altera��o de qualquer campo do Formul�rio
*/
	ElseIf cIDPonto == 'BUTTONBAR'
/*
		Adicionando um bot�o na barra de bot�es da rotina
*/
	ElseIf cIDPonto == 'FORMPOS'
/*
		Chamada na valida��o final do formul�rio
*/
	ElseIf  cIDPonto == 'MODELPOS'
/*
		Chamada na valida��o total do modelo
*/
	ElseIf cIDPonto == 'FORMCOMMITTTSPRE'
/*
		Chamada antes da grava��o da tabela do formul�rio
*/
	ElseIf cIDPonto == 'FORMCOMMITTTSPOS'
/*
		Chamada ap�s a grava��o da tabela do formul�rio
*/
	ElseIf cIDPonto == 'MODELCOMMITTTS'
/*
		Chamada ap�s a grava��o total do modelo e dentro da transa��o
*/
	ElseIf cIDPonto == 'MODELCOMMITNTTS'
/*
		Chamada ap�s a grava��o total do modelo e fora da transa��o
*/
		if !empty(oObj:GetModel('SA2MASTER'):GetValue('A2_TPOSTO'))
			oAPIPosto := Telecontrol.Integracao.Posto.TTLCPosto():New()
			if nOpc == MODEL_OPERATION_INSERT // inclus�o
				if isBlind()
					oAPIPosto:Cadastra()
				else
					FwMsgRun(NIL, {|| lOk := oAPIPosto:Cadastra()}, "Telecontrol", "Gravando informa��es...")
					if !lOk
						FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
					endif
				endif
			elseif nOpc == MODEL_OPERATION_UPDATE // altera��o	
				// consulta o Posto no telecontrol
				cCodRet := '500'
				if !oAPIPosto:Consulta(,@cCodRet,,.F.,.F.) .OR. (cCodRet <> '200') // se n�o existia, ent�o inclui
					if isBlind()
						oAPIPosto:Cadastra()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPosto:Cadastra()}, "Telecontrol", "Gravando informa��es...")
						if !lOk
							FWAlertWarning("N�o foi poss�vel efetuar o cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				elseif (cCodRet == '200') // se j� existia, ent�o altera
					if isBlind()
						oAPIPosto:Altera()
					else
						FwMsgRun(NIL, {|| lOk := oAPIPosto:Altera()}, "Telecontrol", "Atualizando informa��es...")
						if !lOk
							FWAlertWarning("N�o foi poss�vel efetuar a altera��o do cadastro junto ao Telecontrol. Verifique o LOG para mais detalhes", "Telecontrol")
						endif
					endif
				endif
			endif
			FWFreeObj(oAPIPosto)
		endif

	ElseIf cIDPonto == 'MODELCANCEL'
/*
		Chamada ap�s o cancelamento da edi��o do cadastro de fornecedores
*/
	EndIf

EndIf
 
Return xRet

