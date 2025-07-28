#include "totvs.ch"
#include "fwmvcdef.ch"
#include "parmtype.ch"

Static cTabOServ := GetMV('TI_OSRVTAB', .F., 'SZ7') as character
Static cPrefOServ := if(upper(left(cTabOServ,1))=="S", right(cTabOServ,2), cTabOServ) as character

Static cTabItens := alltrim(GetMV('TI_OSRITAB', .F., 'SZ8'))
Static cPrefItens := if(left(cTabItens,1)=="S", right(cTabItens,2), cTabItens)

Static cTabAnexos := alltrim(GetMV('TI_OSRATAB', .F., 'SZ9'))
Static cPrefAnexos := if(left(cTabAnexos,1)=="S", right(cTabAnexos,2), cTabAnexos)


/*/
{Protheus.doc} TLC_CADOS.TLCOSERV
Cadastro de ordens de serviço
@type  Function
@author Emerson Nascimento
@since 05/06/2025
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER FUNCTION TLCOSERV() //U_TLCOSERV()
Local AreaAt := GetArea() as array
Local cFunBkp := FUNNAME() as character

	cTitulo := 'Ordens de Serviço'

	chkFile(cTabOServ)
	chkFile(cTabItens)
	chkFile(cTabAnexos)

	SetFunName("TLCOSERV")

	chkFile(cTabOServ) // cria/abre a tabela
	dbSelectArea(cTabOServ)

	oBrowse := FWMBrowse():New()
	oBrowse:setMenuDef('TLC_CADOS')
	oBrowse:setAlias(cTabOServ)
	oBrowse:setDescription(cTitulo)
	oBrowse:Activate()

	// restaura a área de trabalho original
	RestArea(AreaAt)

	SetFunName(cFunBkp)

RETURN


/*/
{Protheus.doc} TLC_CADOS.MenuDef
Cria os itens de menu para a tela de manutenção do cadastro de status Protheus x status Track3r
@type  Function
@author Emerson Nascimento
@since 05/06/2025
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function MenuDef()
Local aRotina := {}

	ADD OPTION aRotina TITLE "Visualizar"	ACTION "VIEWDEF.TLC_CADOS"	OPERATION MODEL_OPERATION_VIEW	ACCESS 0

Return aRotina //FWMVCMenu('TLC_CADOS')


/*/
{Protheus.doc} TLC_CADOS.ModelDef
Modelo de dados para manipular a tabela de status Protheus x status Track3r
@type  Function
@author Emerson Nascimento
@since 05/06/2025
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function ModelDef()
Local oStruct := FWFormStruct( 1, cTabOServ, /*bAvalCampo*/,/*lViewUsado*/ ) // ordem de serviço
Local oStructIt := FWFormStruct( 1, cTabItens, /*bAvalCampo*/,/*lViewUsado*/ ) // itens
Local oStructAn := FWFormStruct( 1, cTabAnexos, /*bAvalCampo*/,/*lViewUsado*/ ) // anexos
Local oModel
Local aRelacItens := { { cPrefItens+'_FILIAL', 'xFilial( "' + cTabItens + '" )' }, { cPrefItens+'_NUM', cPrefOServ+'_NUM' } }
Local aRelacAnexos := { { cPrefAnexos+'_FILIAL', 'xFilial( "' + cTabAnexos + '" )' }, { cPrefAnexos+'_NUM', cPrefOServ+'_NUM' } }

	oModel := MPFormModel():New( 'MODELOSERV' )
	oModel:addFields( 'OSMASTER',, oStruct )
	oModel:addGrid( 'OSITENS', 'OSMASTER', oStructIt )
	oModel:addGrid( 'OSANEXOS', 'OSMASTER', oStructAn )

	// faz relacionamento entre os itens e a ordem de serviço
	oModel:setRelation( 'OSITENS', aRelacItens, (cTabItens)->( IndexKey(1) ) )

	// faz relacionamento entre os anexos e a ordem de serviço
	oModel:setRelation( 'OSANEXOS', aRelacAnexos, (cTabAnexos)->( IndexKey(1) ) )

	oModel:setPrimaryKey({cPrefOServ+'_NUM'})

	// Adiciona as descrições do Modelo de dados
	oModel:setDescription( cTitulo )
	oModel:getModel( 'OSITENS' ):setDescription( 'Itens da ordem de serviço' )
	oModel:getModel( 'OSANEXOS' ):setDescription( 'Anexos da ordem de serviço' )

Return oModel


/*/
{Protheus.doc} TLC_CADOS.ViewDef
Apresentação da tabela de status Protheus x status Track3r
@type  Function
@author Emerson Nascimento
@since 05/06/2025
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel := FWLoadModel('TLC_CADOS')
Local oView
// Cria a estrutura a ser usada na View
Local oStruStOS := FWFormStruct( 2, cTabOServ, /*bAvalCampo*/,/*lViewUsado*/ )
Local oStruStIt := FWFormStruct( 2, cTabItens, /*bAvalCampo*/,/*lViewUsado*/ )
Local oStruStAn := FWFormStruct( 2, cTabAnexos, /*bAvalCampo*/,/*lViewUsado*/ )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:setModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:addField( 'VIEW_OS', oStruStOS, 'OSMASTER' )

	oView:addGrid( 'VIEW_IT', oStruStIt, 'OSITENS' )
	oView:addGrid( 'VIEW_AN', oStruStAn, 'OSANEXOS' )

	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'EMCIMA' , 65 )
	oView:CreateHorizontalBox( 'EMBAIXO', 35 )

	// Criar "folder" para receber os itens e os anexos
	oView:CreateFolder( 'PASTAS', 'EMBAIXO' )

	// Cria pastas na folder
	oView:AddSheet( 'PASTAS', 'ABA01', 'Itens' )
	oView:AddSheet( 'PASTAS', 'ABA02', 'Anexos' )

	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'ITENS', 100,,, 'PASTAS', 'ABA01' )
	oView:CreateHorizontalBox( 'ANEXOS', 100,,, 'PASTAS', 'ABA02' )

	// Relaciona o ID da View com o "box" para exibicao
	oView:setOwnerView( 'VIEW_OS', 'EMCIMA' )
	oView:setOwnerView( 'VIEW_IT', 'ITENS' )
	oView:setOwnerView( 'VIEW_AN', 'ANEXOS' )

	// Liga a identificacao do componente
	oView:EnableTitleView( 'VIEW_OS', cTitulo )

//ShellExecute("Open", cLink, "", "", 1)
Return oView
