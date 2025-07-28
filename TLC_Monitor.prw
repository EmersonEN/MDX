#include "totvs.ch"
#include "parmtype.ch"
#include 'FWMVCDef.ch'

#define DEF_VERSAO		"V1.000"

/*/{Protheus.doc} TLCMONIT
	Monitor de integrações do Telecontrol
	@type  user function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
User Function TLCMONIT() //U_TLCMONIT()
Local AreaAt := GetArea() as array
Local cFunBkp := FunName() as character
Private oBrowse	as object //:= FWMBrowse():New()
Private aRotina := MenuDef() as array
Private oLOG as object // := Telecontrol.Classe.TTLCLog():New()

	oLOG := Telecontrol.Classe.TTLCLog():New()

	if empty(oLOG:cAliasLOG) .OR. !chkFile(oLOG:cAliasLOG)
		if empty(oLOG:cAliasLOG)
			FWAlertError('A tabela de LOG não foi informada!')
		else
			FWAlertError('A tabela de LOG ('+oLOG:cAliasLOG+') não existe na base de dados!')
		endif
		return
	else
		//cAliasLOG := oLOG:cAliasLOG

		SetFunName('TLCMONIT')

		dbSelectArea(oLOG:cAliasLOG)
		dbSetOrder(1)

		oBrowse	:= FWMBrowse():New()

		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS $ ' /1'", "WHITE", "Aguardando integração")
		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS == '2'", "RED", "Erro ao transmitir o registro")
		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS == '3'", "BLUE", "Registrio transmitido, porém o ID não foi gravado")
		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS == '4'", "BROWN", "Registro transmitido, porém o retorno não é válido (impossível obter o ID)")
//		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS == '5'", "WHITE", "Aguardando integração")
		oBrowse:AddLegend(oLOG:cAliasLOG+"->"+oLOG:cPrefCampo+"_STATUS == 'X'", "GREEN", "Registro transmitido/recebido com sucesso")

		oBrowse:SetAlias(oLOG:cAliasLOG)
		oBrowse:SetDescription("Telecontrol - Monitor de integração " + DEF_VERSAO)
		//oBrowse:SetFilterDefault( cFiltro )

		oBrowse:Activate()

		SetFunName(cFunBkp)

		FWFreeObj(@oBrowse)

	endif

	FWFreeObj(@oLOG)

	RestArea(AreaAt)

Return


/*/{Protheus.doc} TLCMONIT.MenuDef
	Menu de opções do monitor de integrações do Telecontrol
	@type  static function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function MenuDef() as array
Local aRotina as array

	aRotina := {}

	ADD OPTION aRotina TITLE "Visualizar"	ACTION "VIEWDEF.TLC_MONITOR"	OPERATION MODEL_OPERATION_VIEW	ACCESS 0
	ADD OPTION aRotina TITLE "Reenviar"		ACTION "U_TLCREENV"				OPERATION 9						ACCESS 0

Return aRotina


/*/{Protheus.doc} TLCMONIT.ModelDef
	Modelo de dados do monitor de integrações do Telecontrol
	@type  static function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function ModelDef() as object
Local cAliasLOG := alltrim(GetMV('TI_LOGTAB', .F., 'SZ0')) as character
Local cPrefCampo := if(left(cAliasLOG,1) == "S", right(cAliasLOG,2), cAliasLOG) as character
Local oStruLOG := FWFormStruct(1,cAliasLOG)
Local oModel as object
Local aPrimKey := {} as array

	aAdd(aPrimKey, cPrefCampo+"_FILIAL")
	aAdd(aPrimKey, cPrefCampo+"_API")
	aAdd(aPrimKey, cPrefCampo+"_DATA")
	aAdd(aPrimKey, cPrefCampo+"_HORA")
	aAdd(aPrimKey, cPrefCampo+"_TABELA")
	aAdd(aPrimKey, cPrefCampo+"_RECNO")
	aAdd(aPrimKey, cPrefCampo+"_STATUS")
	aAdd(aPrimKey, cPrefCampo+"_RECNO")
	aAdd(aPrimKey, cPrefCampo+"_IDRET")
	aAdd(aPrimKey, cPrefCampo+"_CLASSE")

	oModel := MPFormModel():New('LOGMONITM')
	oModel:AddFields('LOGMASTER',,oStruLOG)

	oModel:SetPrimaryKey(aPrimKey)

	oModel:SetDescription('Modelo de dados do monitor de integração Telecontrol')
	oModel:GetModel('LOGMASTER'):SetDescription('Monitor de integração Telecontrol')

Return oModel


/*/{Protheus.doc} TLCMONIT.ViewDef
	Exibe os dados do monitor de integrações do Telecontrol
	@type  static function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function ViewDef() as object
Local cAliasLOG := alltrim(GetMV('TI_LOGTAB', .F., 'SZ0')) as character
Local oStruLOG := FWFormStruct(2,cAliasLOG)
Local oModel := ModelDef() as object
Local oView as object

	oView := FWFormView():New()

	oView:SetModel(oModel)
	oView:AddField('VIEWLOG', oStruLOG, 'LOGMASTER')

	oView:CreateHorizontalBox('TELALOG', 100)
	oView:SetOwnerView('VIEWLOG', 'TELALOG')

Return oView


User Function TLCREENV(cAlias, nRecno, nOpc)
Local cPrefCampo := oLOG:cPrefCampo as character
Local cAliasRest := (cAlias)->&(cPrefCampo+'_TABELA') as character
Local cPrefRest := if(left(cAliasRest,1)=="S", right(cAliasRest,2), cAliasRest)
Local nRecnoRest := (cAlias)->&(cPrefCampo+'_RECNO') as character
Local cCampoIDRest as character
Local lExisteCampoID as logical
Local cClasse as character
Local cMetodo as character
Local cIDRegistro as character
Local nPonto as numeric
Local oClasse as object

	oLOG:nRegistroLOG := (cAlias)->(Recno())

	// Cria a classe de integração
	cClasse := alltrim((cAlias)->&(cPrefCampo+'_CLASSE'))
	nPonto := RAt('.', cClasse)
	cMetodo := right(cClasse, len(cClasse)-nPonto)
	cClasse := left(cClasse, nPonto-1)
	if !empty(cClasse) .AND. !empty(cMetodo)
		oClasse := &('Telecontrol.Integracao.'+cClasse+'()'):New()
	endif

	if (cAlias)->&(cPrefCampo+'_STATUS') == 'X'
		FWAlertInfo('Reenvio não realizado: este registro foi integrado com sucesso e não precisa ser reenviado.', 'Integração Telecontrol')
	elseif MsgYesNo('Deseja reenviar o registro?', 'Integração Telecontrol')
		(cAliasRest)->(dbGoTo(nRecnoRest))

		if (cAliasRest)->(Recno()) == nRecnoRest
			// se houver um IDRET informado, mas o campo XIDTLC da tabela estiver vazio, apenas atribui o ID
			cIDRegistro := (cAlias)->&(cPrefCampo+'_IDRET')
			cCampoIDRest := cPrefRest+'_XIDTLC'
			lExisteCampoID := ((cAliasRest)->(FieldPos(cCampoIDRest)) > 0)

			// 'Registro transmitido com sucesso, mas NÃO foi possível gravar o ID no registro'
			if ((cAlias)->&(cPrefCampo+'_STATUS') == '3') .AND. !empty(cIDRegistro) .AND. lExisteCampoID .AND. empty((cAliasRest)->&(cCampoIDRest))
				// tenta atribuir o ID ao registro integrado
				Reclock(cAliasRest, .F.)
				(cAliasRest)->&(cCampoIDRest) := cIDRegistro
				(cAliasRest)->(MSUnlock())

				// agora tento alterar o status do log
				Reclock(cAlias, .F.)
				(cAlias)->&(cPrefCampo+'_STATUS') := 'X'
				(cAlias)->(MSUnlock())

				FWAlertSuccess('Processamento executado com sucesso. O ID foi atribuído ao registro', 'Integração Telecontrol')

			// 'Registro transmitido com sucesso, mas o retorno não é um json válido (impossível obter o ID)'
			elseif ((cAlias)->&(cPrefCampo+'_STATUS') == '4') .AND. lExisteCampoID .AND. empty((cAliasRest)->&(cCampoIDRest)) .AND. !empty((cAlias)->&(cPrefCampo+'_RET'))
				lOk := .F.

				if (valtype(oClasse) == "O") .AND. empty(cIDRegistro) .AND. lExisteCampoID .AND. empty((cAliasRest)->&(cCampoIDRest))
					// tenta obter o ID a partir do json retorno
					objRetorno := jsonObject():New()
					cRetJson := objRetorno:fromJson((cAlias)->&(cPrefCampo+'_RET'))
					cIDRegistro := Eval(&(oClasse:cTagID))

					if (valtype(cRetJson) == "U") .AND. !empty(cIDRegistro) .AND. oClasse:GravaID(cIDRegistro)
						oLOG:cHistorico := 'Registro transmitido e ID gravado com sucesso'
						oLOG:cStatus := 'X'
						oLOG:AlteraLOG('[SUCCESS]')
						lOk := .T.
					endif
				endif

				if !lOk
					FWAlertWarning('Reenvio não realizado: não foi possível encontrar o registro original.', 'Integração Telecontrol')
				endif

			// Qualquer outro status
			else

				if !empty(cClasse) .AND. !empty(cMetodo)
					if &('oClasse:'+cMetodo+'()')
						FWAlertSuccess('Registro reenviado com sucesso!', 'Integração Telecontrol')
					else
						FWAlertError('Problemas ao reenviar o registro. Veja a legenda e os detalhes para identificar o problema.', 'Integração Telecontrol')
					endif
				else
					FWAlertWarning('Reenvio não realizado: não foi possível determinar a classe e método que deverá ser executado.', 'Integração Telecontrol')
				endif

			endif

		else
			FWAlertWarning('Reenvio não realizado: não foi possível encontrar o registro original.', 'Integração Telecontrol')
		endif

	endif

	if !empty(cClasse) .AND. !empty(cMetodo)
		FWFreeObj(@oClasse)
	endif

Return
