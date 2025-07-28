#include "PROTHEUS.CH"
#include "FWMVCDEF.CH"
#include "PARMTYPE.CH"

Static oDadosTela
Static oConfigTela
Static cTitTela
Static aNamesTela
Static cAliasTela
Static cRealName

//-------------------------------------------------------------------
/*/{Protheus.doc} TLC_SHRET
Tela de consulta MVC
@author Emerson Nascimento TwoIT
@since 16/03/2025
@version R2410
/*/
//-------------------------------------------------------------------
User Function TLC_SHRET(cTitulo, oDados, oConfig)
Local AreaAt := GetArea()
Local oTempTable
Local aCampos := {} as array
Local iCampo as numeric
Local cCampo
Local cOrdem := "01"
Local cCampoTag

	oDadosTela := oDados
	oConfigTela := oConfig
	cTitTela := cTitulo
	aNamesTela := oConfigTela:GetNames()

	for iCampo := 1 to len(aNamesTela)
		cCampo := aNamesTela[iCampo]
		cIDCampo := 'CAMPO_'+cOrdem
		aAdd(aCampos, {cIDCampo, Eval(&(oConfigTela[cCampo]['tipo'])), Eval(&(oConfigTela[cCampo]['tamanho'])), Eval(&(oConfigTela[cCampo]['decimal']))})
		oConfigTela[cCampo]['campo_tabela'] := cIDCampo // mapeamento do campo físico x lógico
		cOrdem := Soma1(cOrdem)
	next iCampos

	// cria a tabela temporária e a popula com os dados de oDadosTela
	oTempTable := FWTemporaryTable():New()
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {'CAMPO_01'})
	oTempTable:Create()

	cRealName := oTempTable:GetRealName()
	cAliasTela := oTempTable:GetAlias()

	Reclock(cAliasTela, .T.)
	for iCampo := 1 to len(aNamesTela)
		cCampo := aNamesTela[iCampo]
		if oConfigTela:HasProperty(cCampo)
			cIDCampo := oConfigTela[cCampo]['campo_tabela']
			if oConfigTela[cCampo]:HasProperty('tag')
				cCampoTag := oConfigTela[cCampo]['tag']
				(cAliasTela)->&(cIDCampo) := oDadosTela[cCampo][cCampoTag]
			else
				(cAliasTela)->&(cIDCampo) := oDadosTela[cCampo]
			endif
		else
			Alert('O campo ['+cCampo+'], configurado para apresentação em tela, não foi encontrado no retorno da API')
		endif
	next iCampos
	(cAliasTela)->(MSUnlock())

//	FWExecView(cTitTela,"TLC_SHRET", MODEL_OPERATION_VIEW,, { || .T. } )

	aButtons := {;
		{.F., nil},;		// 1 - Copiar
		{.F., nil},;		// 2 - Recortar
		{.F., nil},;		// 3 - Colar
		{.F., nil},;		// 4 - Calculadora
		{.F., nil},;		// 5 - Spool
		{.F., nil},;		// 6 - Imprimir
		{.F., nil},;		// 7 - Confirmar
		{.T., 'Fechar'},;	// 8 - Cancelar
		{.F., nil},;		// 9 - WalkTrhough
		{.F., nil},;		// 10 - Ambiente
		{.F., nil},;		// 11 - Mashup
		{.F., nil},;		// 12 - Help
		{.F., nil},;		// 13 - Formulário HTML
		{.F., nil} ;		// 14 - ECM
	}

	oExecView := FWViewExec():New()
	oExecView:setTitle(cTitTela)
	oExecView:setSource("TLC_SHRET")
	oExecView:setCloseOnOK({|| .T.})
	oExecView:setOperation(MODEL_OPERATION_VIEW)
	oExecView:setReduction(40) // reduz a tela em 40%
	oExecView:setButtons(aButtons)
	oExecView:openView(.T.)

	oTempTable:Delete()

	RestArea(AreaAt)
Return NIL


//-------------------------------------------------------------------
Static Function ModelDef()
Local cValues as character
Local aValues as array
Local iStru as numeric
Local cCampo as character
Local cIDCampo as character
Local oModel := Nil
Local oStruTmp := FWFormModelStruct():New()

	//define os campos e a temporária
	oStruTmp:AddTable(cAliasTela, {aNamesTela[1]}, cTitTela)

	//Adiciona os campos da estrutura
	for iStru := 1 to len(aNamesTela)
		cCampo := aNamesTela[iStru]
		cIDCampo := upper(oConfigTela[cCampo]['campo_tabela'])
		aValues := {}
		if oConfigTela[cCampo]:HasProperty('cbox')
			cValues := Eval(&(oConfigTela[cCampo]['cbox']))
			if !empty(cValues)
				aValues := StrToKArr2(cValues, ";")
			endif
		endif

		oStruTmp:AddField(;
			Eval(&(oConfigTela[cCampo]['titulo'])),		; // [01] Titulo do campo
			Eval(&(oConfigTela[cCampo]['dica'])),		; // [02] ToolTip do campo
			cIDCampo,									; // [03] Id do Field
			Eval(&(oConfigTela[cCampo]['tipo'])),		; // [04] Tipo do campo
			Eval(&(oConfigTela[cCampo]['tamanho'])),	; // [05] Tamanho do campo
			Eval(&(oConfigTela[cCampo]['decimal'])),	; // [06] Decimal do campo
			{|| .T.},									; // [07] Code-block de validação do campo
			{|| .T.},									; // [08] Code-block de validação When do campo
			aValues,									; // [09] Lista de valores permitidos para o campo
			.F.											; // [10] Indica se o campo tem preenchimento obrigatório
		)
	next iStru

	//Instanciando o modelo
	oModel := MPFormModel():New('MTLC_SHRET') 
	oModel:AddFields("CADASTRO",/*cOwner*/,oStruTmp)
	oModel:SetPrimaryKey({aNamesTela[1]})
	oModel:SetDescription(cTitTela)
	oModel:GetModel('CADASTRO'):SetDescription('Telecontrol')

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()
// Cria a estrutura a ser usada na View
Local oStruTmp := FWFormViewStruct():New()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel( 'TLC_SHRET' )
Local oView
Local iStru as numeric
Local cOrdem := "01" as character

    // a estrutura será montada a partir dos dados recebidos
	cOrdem := "01"
	for iStru := 1 to len(aNamesTela)
		cCampo := aNamesTela[iStru]
		cIDCampo := upper(oConfigTela[cCampo]['campo_tabela'])

		oStruTmp:AddField(;
			cIDCampo,								; // [01] ID do campo
			cOrdem,									; // [02] Ordem
			Eval(&(oConfigTela[cCampo]['titulo'])),	; // [03] Titulo
			Eval(&(oConfigTela[cCampo]['dica'])),	; // [04] Descrição
			{Eval(&(oConfigTela[cCampo]['dica']))},	; // [05] Help
			Eval(&(oConfigTela[cCampo]['tipo'])),	; // [06] Tipo do campo
			'',										; // [07] Picture
			,										; // [08] PictVar
			''										; // [09] F3
		)
		cOrdem := Soma1(cOrdem)
	next iStru

	oView := FWFormView():New()
	oView:SetModel( oModel )
	oView:AddField( 'VIEW_CAD', oStruTmp, 'CADASTRO' )

	oView:CreateHorizontalBox( "TELA", 100 )
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView( "VIEW_CAD", "TELA" )

Return oView
