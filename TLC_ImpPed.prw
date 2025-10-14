#include "totvs.ch"
#include "parmtype.ch"
#include 'topconn.ch'
#include 'tbiconn.ch'

#define DEF_VERSAO		"V1.000"


/*/{Protheus.doc} TLCSCHPV
	Schedule para integração dos pedidos do Telecontrol
	@type  user function
	@author Emerson Nascimento TwoIT
	@since 01/08/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
User Function TLCSCHPV(aParams as array) //U_TLCSCHPV()  // deve ser chamado pelo schedule
Local cCodEmp as character
Local cCodFil as character
Local lOk as logical
Local aEmp as array

	if SELECT('SM0') == 0
		OpenSM0()
	endif
	aEmp := FWLoadSM0()

	if valtype(aParams) <> 'A'
		aParams := {}
	endif

	if len(aParams) == 0
		cCodEmp := aEmp[1][1]
		cCodFil := aEmp[1][2]
	else
		cCodEmp := aParams[1]
		cCodFil := aParams[2]
	endif

	cChvExec := 'TLCSCHPV[E'+alltrim(cCodEmp)+'F'+alltrim(cCodFil)+']'

	// PROTEÇÃO CONTRA EXECUÇÃO SIMULTÂNEA PARA A MESMA EMPRESA E FILIAL.
	// SE A EXECUÇÃO FOR PERMITIDA O ARQUIVO CSV FICARÁ BLOQUEADO
	// PELO APPSERVER, SENDO NECESSÁRIO PARAR O SERVIÇO PARA
	// LIBERAR OS ARQUIVOS
	// EMERSON NASCIMENTO TWOIT
	lLockProcess := LockByName(cChvExec,.F.,.F.)

	if lLockProcess

		RpcSetType(3)
		lOk := RpcSetEnv( cCodEmp,cCodFil,,,'FAT','U_TLCSCHPV("'+cCodEmp+'","'+cCodFil+'")',{'SA1','SB1','SC5','SC6'} )
		
		if lOk
			OpenSxs()
			InitPublic()
			SetsDefault()

			U_TLCIMPPV() // executa a integração dos pedidos para a empresa ativa

			RpcClearEnv()
		else

		endif

		// DESLIGA A PROTEÇÃO CONTRA EXECUÇÃO SIMULTÂNEA PARA A MESMA EMPRESA E FILIAL.
		UnLockByName(cChvExec,.F.,.F.)

	endif

Return

/*/{Protheus.doc} TLCIMPPV
	Integra os pedidos de venda a partir da tabela intermediária
	@type  user function
	@author Emerson Nascimento TwoIT
	@since 28/07/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
User Function TLCIMPPV() //U_TLCIMPPV()
Local cMarca := ThisMark() as character
Local nLimPVImp := GetMV('TI_QTIMPPV', .F., 10) as numeric
Local cQuery as character
Local cIDPed as character
Local nNumItens as numeric
Local nQtdPV := 0 as numeric
Local cErroPedido as character
Local cNumPedido as character
Local lGravouPedido as logical

Private cTabPV := upper(alltrim(GetMV('TI_PEDVTAB', .F., 'SZA'))) as character
Private cPrfPV := if(left(cTabPV,1)=='S',right(cTabPV,2),cTabPV) as character
Private cNmTab := RetSQLName(cTabPV) as character
Private cCpoFilial := cPrfPV+'_FILIAL' as character
Private cCpoIDPed := cPrfPV+'_XIDPED' as character
Private cCpoIDIte := cPrfPV+'_XIDITE' as character
Private cCpoAviso := cPrfPV+'_AVISO' as character
Private cCpoPed := cPrfPV+'_NUM' as character
Private cCpoItem := cPrfPV+'_ITEM' as character
Private cCpoDtInt := cPrfPV+'_DTINT' as character
Private cCpoHrInt := cPrfPV+'_HRINT' as character
Private cCpoCodEmp := cPrfPV+'_EMP' as character
Private cCpoCodFil := cPrfPV+'_FIL' as character
Private cCpoOK := cPrfPV+'_OK' as character
Private cCpoErro := cPrfPV+'_ERRO' as character
Private cCpoMsgErro := cPrfPV+'_MSG' as character
Private cMarcaPed := left(padr(FWTimeStamp() + cMarca,20),20) as character
Private cFilPED := xFilial(cTabPV) as character
Private cFilSC5 := xFilial('SC5') as character
Private cFilSC6 := xFilial('SC6') as character
Private cQryAtualizaPed as character
Private oLOG as object

	// atualiza os registros intermediários com os dados do pedido do Protheus
	cQryAtualizaPed := "UPDATE PED SET "+CRLF
	cQryAtualizaPed += "	PED."+cCpoPed+" = C5.C5_NUM, "+CRLF
	cQryAtualizaPed += "	PED."+cCpoItem+" = COALESCE(C6.C6_ITEM,'XX'), "+CRLF
	cQryAtualizaPed += "	PED."+cCpoDtInt+" = CASE WHEN PED."+cCpoDtInt+" = ' ' THEN CONVERT(VARCHAR(8), GETDATE(), 112) ELSE PED."+cCpoDtInt+" END, "+CRLF
	cQryAtualizaPed += "	PED."+cCpoHrInt+" = CASE WHEN PED."+cCpoHrInt+" = ' ' THEN CONVERT(VARCHAR(8), GETDATE(), 108) ELSE PED."+cCpoHrInt+" END "+CRLF
	cQryAtualizaPed += "FROM "+CRLF
	cQryAtualizaPed += "	"+cNmTab+" PED "+CRLF
	cQryAtualizaPed += "INNER JOIN "+CRLF
	cQryAtualizaPed += "	"+RetSQLName('SC5')+" C5 "+CRLF
	cQryAtualizaPed += "	ON C5.D_E_L_E_T_ = '' AND C5.C5_FILIAL = '" + cFilSC5 + "' "+CRLF
	cQryAtualizaPed += "	AND C5.C5_XIDTLC = PED."+cCpoIDPed+" "+CRLF
	cQryAtualizaPed += "LEFT JOIN "+CRLF
	cQryAtualizaPed += "	"+RetSQLName('SC6')+" C6 "+CRLF
	cQryAtualizaPed += "	ON C6.D_E_L_E_T_ = '' AND C6.C6_FILIAL = '" + cFilSC6 + "' "+CRLF
	cQryAtualizaPed += "	AND C6.C6_NUM = C5.C5_NUM "+CRLF
	cQryAtualizaPed += "	AND C6.C6_XIDTLC = PED."+cCpoIDIte+" "+CRLF
	cQryAtualizaPed += "WHERE PED.D_E_L_E_T_ = ' ' "+CRLF
	cQryAtualizaPed += "	AND PED."+cCpoFilial+" = '" + cFilPED + "' "+CRLF
	cQryAtualizaPed += "	AND PED."+cCpoCodEmp+" = '" + cEmpAnt + "' "+CRLF
	cQryAtualizaPed += "	AND PED."+cCpoCodFil+" = '" + cFilAnt + "' "+CRLF
	cQryAtualizaPed += "	AND PED."+cCpoIDPed+" = '[CIDPEDIDOVENDA]'"+CRLF

	// procura pedidos disponíveis para integração
	cQuery := '	SELECT '+CRLF
	cQuery += '		PED.'+cCpoFilial+', PED.'+cCpoCodEmp+', PED.'+cCpoCodFil+', '+CRLF
	cQuery += '		'+cCpoIDPed+' IDPED, COUNT(*) ITENS, '+CRLF
	cQuery += '		(SELECT COUNT(*) FROM '+cNmTab+' TMP '+CRLF
	cQuery += "		WHERE TMP.D_E_L_E_T_ = ' '"+CRLF
	cQuery += '		AND TMP.'+cCpoFilial+' = PED.'+cCpoFilial+' '+CRLF
	cQuery += '		AND TMP.'+cCpoCodEmp+' = PED.'+cCpoCodEmp+' '+CRLF
	cQuery += '		AND TMP.'+cCpoCodFil+' = PED.'+cCpoCodFil+' '+CRLF
	cQuery += '		AND TMP.'+cCpoIDPed+' = PED.'+cCpoIDPed+') TOTITENS '+CRLF
	cQuery += '	FROM '+cNmTab+' PED '+CRLF
	cQuery += "	WHERE PED.D_E_L_E_T_ = ' '"+CRLF
	cQuery += '	AND PED.'+cCpoFilial+" = '" + cFilPED + "' "+CRLF
	cQuery += '	AND PED.'+cCpoCodEmp+" = '" + cEmpAnt + "' "+CRLF
	cQuery += '	AND PED.'+cCpoCodFil+" = '" + cFilAnt + "' "+CRLF
	cQuery += '	AND PED.'+cCpoPed+" = ' ' "+CRLF
	cQuery += '	AND PED.'+cCpoOK+" = ' ' "+CRLF
	cQuery += '	AND PED.'+cCpoErro+" = ' ' "+CRLF
	cQuery += '	GROUP BY PED.'+cCpoFilial+', PED.'+cCpoCodEmp+', PED.'+cCpoCodFil+', PED.'+cCpoIDPed+CRLF

	dbUseArea(.T., 'topconn', tcgenqry(,,cQuery), 'TMPPED', .F., .T.)

	while !TMPPED->(EOF()) .AND. (nQtdPV <= nLimPVImp)
		nQtdPV++

		cIDPed := TMPPED->IDPED
		nNumItens := TMPPED->ITENS

		oLOG := Telecontrol.Classe.TTLCLog():New()
		oLOG:cAPI := 'GravaPedido'
		oLOG:cDescricao := 'Grava o pedido de venda'
		oLOG:cTabela := 'SC5'
		oLOG:cStatus := ' '

		if TMPPED->ITENS <> TMPPED->TOTITENS

			cErroPedido := '{'+CRLF
			cErroPedido += '	"mensagem": "O número de itens disponíveis para integração é diferente do número total de itens do pedido. Verifique a tabela intermediária'+CRLF
			cErroPedido += '}'+CRLF

			oLOG:cStatus := '2'
			oLOG:cHistorico := 'Pedido '+alltrim(cIDPed)+': o número de itens disponíves difere do total de itens'
			oLOG:cJsonRetorno := cErroPedido
			oLOG:cTabela := 'SC5'
			oLOG:nRegistro := 0

		else

			// verifica se o pedido já está integrado
			cQuery  := "SELECT MAX(C5_NUM) PEDIDO FROM " + RETSQLNAME("SC5") + " WHERE D_E_L_E_T_ = '' AND C5_FILIAL = '"+cFilSC5+"' AND C5_XIDTLC = '"+cIDPed+"' "
			cNumPedido := alltrim(MPSysExecScalar(cQuery, "PEDIDO"))
			lGravouPedido := !empty(cNumPedido)

			if !lGravouPedido
				lGravouPedido := GravaPedido(cIDPed, nNumItens)
			endif

			if lGravouPedido
				AtualizaPedido(cIDPed)
			endif

		endif

		if oLOG:cStatus == '2'
			oLOG:GravaLOG('[ERROR]')
		else
			oLOG:GravaLOG('[SUCCESS]')
		endif
		FWFreeObj(@oLOG)

		TMPPED->(dbSkip())
	enddo

	// atualiza informações no Telecontrol para todos os pedidos que tenham sido
	// integrados e ainda não enviaram os dados de integração para o Telecontrol
	AtualizaTelecontrol()

Return


/*/{Protheus.doc} GravaPedido
	Prepara os registros intermediário para gravação do pedido de venda
	@type  static function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function GravaPedido(cIDPedidoVenda as character, nNumItens as numeric)
Local lGravouPedido := .F. as logical
Local cQuery as character
//Local cUpdate as character
Local cCodProd as character
Local cProdErro as character
Local cCodCli as character
Local cLojCli as character
Local cCNPJCliente as character
Local lCabecalho := .T. as logical
Local aCabec := {} as array
Local aItens := {} as array
Local cErroPedido as character
//Local dDataProc as date
//Local cHoraProc as character

	Begin Transaction

		cQuery := "UPDATE "+cNmTab+" SET "+CRLF
		cQuery += "	"+cCpoOK+" = '"+cMarcaPed+"' "+CRLF
		cQuery += "WHERE D_E_L_E_T_ = ' ' "+CRLF
		cQuery += '	AND '+cCpoFilial+" = '" + cFilPED + "' "+CRLF
		cQuery += '	AND '+cCpoCodEmp+" = '" + cEmpAnt + "' "+CRLF
		cQuery += '	AND '+cCpoCodFil+" = '" + cFilAnt + "' "+CRLF
		cQuery += '	AND '+cCpoOK+" = ' ' "+CRLF
		cQuery += '	AND '+cCpoIDPed+" = '"+cIDPedidoVenda+"' "+CRLF

		if TCSQLExec(cQuery) < 0 // ERRO !!!

			cErroPedido := '{'+CRLF
			cErroPedido += '	"mensagem": "Não foi possível reservar os itens do pedido '+cIDPedidoVenda+' para gerar o pedido Protheus na empresa '+cEmpAnt+', filial '+cFilAnt+'"'+CRLF
			cErroPedido += '}'+CRLF

			oLOG:cStatus := '2'
			oLOG:cHistorico := 'O pedido '+alltrim(cIDPedidoVenda)+' não foi integrado'
			oLOG:cJsonRetorno := cErroPedido
			oLOG:cTabela := 'SC5'
			oLOG:nRegistro := 0

		else

			(cTabPV)->(dbSetOrder(1)) // _FILIAL, _XIDPED
			(cTabPV)->(dbSeek(cFilPED + cIDPedidoVenda))

			aCabec := {}
			aItens := {}
			lCabecalho := .T.

			cProdErro := ''
			cErroPedido := ''
			cTipoPed := ''

			// monta os itens do pedido
			while !(cTabPV)->(EOF()) .AND. ((cTabPV)->&(cCpoFilial) == cFilPED) .AND. ((cTabPV)->&(cCpoIDPed) == cIDPedidoVenda) .AND. ((cTabPV)->&(cCpoOK) == cMarcaPed)

				if empty(cTipoPed)
					cTipoPed := (cTabPV)->&(cPrfPV+'_TPPED') // GAR / VENDA / TROCA

					// cabeçalho GARANTIA
					cTipo := 'N' // normal
					cTransp := '000136' // SEDEX
					cCondPg = if(empty((cTabPV)->&(cPrfPV+'_COND')),'001',(cTabPV)->&(cPrfPV+'_COND')) // a vista
					cVend1 := '703' // pos venda
					cTipoVenda := '6' // pos venda
					cNaturez := '1106' // venda de produtos de seguranca
					cTipoTrans := '1' // rodoviário
					cTipoFrt := if(empty((cTabPV)->&(cPrfPV+'_TPFRT')), 'C', left((cTabPV)->&(cPrfPV+'_TPFRT'),1)) // CIF
					cFaturado := '1' // Imediato
					lUsaCorreios := .T.
					cMensNota := "Remessa de troca em garantia, ARM 01, Nome Cliente, OS, Chamado, Postos Autorizado"
					cTipoCliente := 'F' // consumiodor final

					// item GARANTIA
					cLocal := '01' // produto novo
					cTpOper := 'Y' // retorno de remessa de troca
					cTES := '690' // retorno de troca em garantia
					//Preço Unitário = De acordo com a nota de compra do cliente

					if cTipoPed == 'VEN' // venda
						// cabeçalho
						lUsaCorreios := .F.
						cMensNota := "Pedido, Remessa de troca em garantia, ARM 01, Nome Cliente, OS, Chamado, Postos Autorizado"
						cTipoCliente := 'R'

						// item
						cTpOper := '01' // venda
						cTES := '501'
					endif
				endif

				// monta o cabeçalho do pedido
				if lCabecalho
					cCNPJCliente := ALLTRIM((cTabPV)->&(cPrfPV+'_CLI'))
					SA1->(dbSetOrder(3)) // A1_FILIAL, A1_CGC
					if SA1->(dbSeek(xFilial() + cCNPJCliente))
						cCodCli := SA1->A1_COD
						cLojCli := SA1->A1_LOJA
					else
						cCodCli := ''
						cLojCli := ''

						cErroPedido := '{'+CRLF
						cErroPedido += '	"mensagem": "Não há um cliente cadastrado com o CNPJ ['+cCNPJCliente+'] na empresa '+cEmpAnt+', filial '+cFilAnt+'"'+CRLF
						cErroPedido += '}'+CRLF

						oLOG:cStatus := '2'
						oLOG:cHistorico := 'O pedido '+alltrim(cIDPedidoVenda)+' não foi integrado'
						oLOG:cJsonRetorno := cErroPedido
						oLOG:cTabela := 'SC5'
						oLOG:nRegistro := 0
					endif
					aAdd(aCabec, {'C5_TIPO', cTipo, nil}) // N-normal/D-dev.compras/C-compl.prc, qtde/P-compl.IPI/I-compl.ICMS/B-benef
					aAdd(aCabec, {'C5_XIDTLC', (cTabPV)->&(cPrfPV+'_XIDPED'), nil})
					aAdd(aCabec, {'C5_CLIENTE', cCodCli, nil})
					aAdd(aCabec, {'C5_LOJACLI', cLojCli, nil})
					aAdd(aCabec, {'C5_TRANSP', cTransp, nil})
					aAdd(aCabec, {'C5_TPFRETE', cTipoFrt, nil}) // C-cof/F-fob
					aAdd(aCabec, {'C5_CONDPAG', cCondPg, nil})
					if !empty((cTabPV)->&(cPrfPV+'_ENTREG'))
						aAdd(aCabec, {'C5_SUGENT', (cTabPV)->&(cPrfPV+'_COND'), nil})
					endif
					aAdd(aCabec, {'C5_VEND1', cVend1, nil})
					aAdd(aCabec, {'C5_TPVEN', cTipoVenda, nil}) // 1-normal/2-bx,giro/3-commcenter/4-mktplace/5-funcionario/6-pos venda/7-imp.direta/8-bonif, demonstr/9-crm/10-projeto
					aAdd(aCabec, {'C5_NATUREZ', cNaturez, nil})
					aAdd(aCabec, {'C5_TPTRANS', cTipoTrans, nil}) // 1-rodoviario/2-aereo/3-maritimo
					aAdd(aCabec, {'C5_FATUR', cFaturado, nil}) // 1-imediato/2-credito/3-programado/4-sem estq/5-env.manual
					aAdd(aCabec, {'C5_XCORREI', if(lUsaCorreios,'S','N'), nil}) // S-sim/N-não
					aAdd(aCabec, {'C5_MENNOTA', cMensNota, nil})
					aAdd(aCabec, {'C5_TIPOCLI', cTipoCliente, nil}) // R=revendedor/S=solidário/F-cons.final

					lCabecalho := .F.
				endif

				cCodProd := alltrim((cTabPV)->&(cPrfPV+'_PROD'))

				SB1->(dbSetOrder(1)) // B1_FILIAL, B1_COD
				if !SB1->(dbSeek(xFilial() + cCodProd))
					oLOG:cStatus := '2'
					cProdErro += (if(empty(cProdErro),'',', ') + cCodProd)
				endif

				aItem := {}
				aAdd(aItem, {'C6_PRODUTO', (cTabPV)->&(cPrfPV+'_PROD'), nil})
				aAdd(aItem, {'C6_QTDVEN', (cTabPV)->&(cPrfPV+'_QTDVEN'), nil})
				aAdd(aItem, {'C6_PRCVEN', (cTabPV)->&(cPrfPV+'_PRCVEN'), nil}) // Preço Unitário = De acordo com a nota de compra do cliente
				aAdd(aItem, {'C6_XIDTLC', (cTabPV)->&(cPrfPV+'_XIDITE'), nil})
				aAdd(aItem, {'C6_XIDOS', (cTabPV)->&(cPrfPV+'_IDOS'), nil})
				aAdd(aItem, {'C6_OPER', cTpOper, nil})
				aAdd(aItem, {'C6_TES', cTES, nil})
				aAdd(aItem, {'C6_LOCAL', cLocal, nil})
				aAdd(aItem, {'C6_QTDLIB', (cTabPV)->&(cPrfPV+'_QTDVEN'), nil})

				aAdd(aItens, aItem)

				(cTabPV)->(dbSkip())
			enddo

			// se conseguiu reservar o pedido, efetua a integração
			if empty(oLOG:cStatus)

				if (len(aItens) == nNumItens)

					lGravouPedido := GravaPV(aCabec, aItens, @cErroPedido)

					if lGravouPedido
						oLOG:cStatus := 'X'
						oLOG:cHistorico := 'Pedido '+alltrim(cIDPedidoVenda)+' integrado com sucesso'
						oLOG:cJsonRetorno := ''
						oLOG:nRegistro := SC5->(Recno())
						oLOG:cIDRegistro := SC5->C5_NUM
					else
						(cTabPV)->(dbSetOrder(1)) // _FILIAL, _XIDPED
						(cTabPV)->(dbSeek(cFilPED + cIDPedidoVenda))

						while !(cTabPV)->(EOF()) .AND. ((cTabPV)->&(cCpoIDPed) == cIDPedidoVenda)

							// preenche as informações na tabela intermediária
							RecLock(cTabPV, .F.)
							(cTabPV)->&(cCpoErro) := 'S'
							(cTabPV)->&(cCpoMsgErro) := cErroPedido
							(cTabPV)->(MSUnlock())

							(cTabPV)->(dbSkip())
						enddo

						oLOG:cStatus := '2'
						oLOG:cHistorico := 'O pedido '+alltrim(cIDPedidoVenda)+' não foi integrado'
						oLOG:cJsonRetorno := cErroPedido
						oLOG:cTabela := 'SC5'
						oLOG:nRegistro := 0
					endif

				else

					cErroPedido := '{'+CRLF
					cErroPedido += '	"mensagem": "O número de itens reservados não corresponte ao numero de itens do pedido"'+CRLF
					cErroPedido += '}'+CRLF

					oLOG:cStatus := '2'
					oLOG:cHistorico := 'Número de itens errado.'
					oLOG:cJsonRetorno := cErroPedido
					oLOG:cTabela := 'SC5'
					oLOG:nRegistro := 0

				endif

			elseif empty(cErroPedido) .AND. !empty(cProdErro)

				cErroPedido := '{'+CRLF
				cErroPedido += '	"mensagem": "Os produtos '+cProdErro+' não foram encontrados"'+CRLF
				cErroPedido += '}'+CRLF

				oLOG:cStatus := '2'
				oLOG:cHistorico := 'O pedido '+alltrim(cIDPedidoVenda)+' não foi integrado'
				oLOG:cJsonRetorno := cErroPedido

			endif

		endif

		// retira a reserva do registro do pedido
		TCSQLExec('UPDATE '+cNmTab+' SET '+cCpoOK+" = ' ' WHERE D_E_L_E_T_ = ' ' AND "+cCpoOK+" = '"+cMarcaPed+"' AND "+cCpoIDPed+" = '"+cIDPedidoVenda+"'")

	End Transaction

Return lGravouPedido


/*/{Protheus.doc} GravaPedido
	Grava o pedido de venda
	@type  static function
	@author Emerson Nascimento TwoIT
	@since 16/03/2025
	@version 1.000
	@param nil
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function GravaPV(aMata410Cab as array, aMata410Item as array, cRetorno as character)
Local nI
Local aErroAuto as array
Local nTotErAuto as numeric

	lMsErroAuto := .F.
	lAutoErrNoFile := .T. // indica que deve ser gerado o array e não o arquivo com os erros

	cRetorno := ''

	// Rotina automatica do pedido de venda
	MSExecAuto({|x,y,z| Mata410(x,y,z)}, aMata410Cab, aMata410Item, 3) // somente inclusão

	// Erro
	If lMsErroAuto
		aErroAuto  := GetAutoGRLog()
		nTotErAuto := Len(aErroAuto)

		if nTotErAuto > 0
			cRetorno := StrTran( StrTran( aErroAuto[1], "<", "" ), "-", "" ) + (" ")
			For nI := 2 To nTotErAuto
				if ('INVALIDO' $ upper(FWNoAccent(aErroAuto[nI])))
					cRetorno += if(empty(cRetorno),'',CRLF) + StrTran( StrTran( aErroAuto[nI], "<", "" ), "-", "" ) + (" ")
				endif
			Next nI
		endif

		if empty(cRetorno)
			cRetorno := 'Problema ao tentar gravar o pedido. Erro indeterminado. Simule a gravação manual deste pedido para identificar o erro.'
		endif
	EndIf

	aErroAuto  := {}
	nTotErAuto := 0

Return !lMsErroAuto


Static Function AtualizaPedido(cIDPedidoVenda as character)
Local cQuery as character

	cQuery := StrTran(cQryAtualizaPed,'[CIDPEDIDOVENDA]',cIDPedidoVenda)

Return (TCSQLExec(cQuery) >= 0)


Static Function AtualizaTelecontrol(cIDPedidoVenda as character)
Local cNewAlias := GetNextAlias() as character
Local cDataHora as chamada
Local cQuery as character
Local lAvisouTlc := .F. as logical
Local AreaAt := GetArea()
Local oAPIPedidoVenda as object
Default cIDPedidoVenda := ''

	cQuery := "SELECT "+CRLF
	cQuery += "	"+cCpoIDPed+" IDPEDIDO, "+CRLF
	cQuery += "	"+cCpoPed+" PEDIDO, "+CRLF
	cQuery += "	MAX("+cCpoDtInt+") DATAINT, "+CRLF
	cQuery += "	MAX("+cCpoHrInt+") HORAINT "+CRLF
	cQuery += "FROM "+cNmTab+" (NOLOCK) "+CRLF
	cQuery += "WHERE D_E_L_E_T_ = ' ' "+CRLF
	cQuery += "	AND "+cCpoFilial+" = '"+cFilPED+"' "+CRLF
	cQuery += "	AND "+cCpoCodEmp+" = '"+cEmpAnt+"' "+CRLF
	cQuery += "	AND "+cCpoCodFil+" = '"+cFilAnt+"' "+CRLF
	cQuery += "	AND "+cCpoPed+" > ' ' "+CRLF
	cQuery += "	AND "+cCpoAviso+" IN (' ', 'F') "+CRLF
	if !empty(cIDPedidoVenda)
		cQuery += "	AND "+cCpoIDPed+" = '"+cIDPedidoVenda+"' "+CRLF
	endif
	cQuery += "GROUP BY "+cCpoIDPed+", "+cCpoPed+" "+CRLF
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery), cNewAlias, .F., .T.)

	while !(cNewAlias)->(EOF())
		cIDPedidoVenda := (cNewAlias)->IDPEDIDO

		if !(cNewAlias)->(EOF()) .AND. !empty((cNewAlias)->PEDIDO) .AND. !empty((cNewAlias)->DATAINT) .AND. !empty((cNewAlias)->HORAINT)
			cDataHora := StrTran(FWTimeStamp(3, stod((cNewAlias)->DATAINT), (cNewAlias)->HORAINT),'T',' ')
			// informa ao Telecontrol que o pedido foi integrado
			oAPIPedidoVenda := Telecontrol.Integracao.PedidoVenda.TTLCPedidoVenda():New('pedidovenda', 'SC5')
			lAvisouTlc := oAPIPedidoVenda:AvisoDeImportacaoDePedidoVenda((cNewAlias)->PEDIDO,,,cDataHora)
			FWFreeObj(@oAPIPedidoVenda)
			if lAvisouTlc
				TCSQLExec('UPDATE '+cNmTab+' SET '+cCpoAviso+" = 'T' WHERE D_E_L_E_T_ = ' ' AND "+cCpoIDPed+" = '"+cIDPedidoVenda+"' AND "+cCpoCodEmp+" = '"+cEmpAnt+"' AND "+cCpoCodFil+" = '"+cFilAnt+"' ")
			endif
		endif

		(cNewAlias)->(dbSkip())

	enddo

	(cNewAlias)->(dbCloseArea())

	RestArea(AreaAt)

Return lAvisouTlc
