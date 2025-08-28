#include "totvs.ch"


/*/{Protheus.doc} M521DNFS
Exclusão da NF saida - Este ponto de entrada está contido na função MaDelNfs e será executado após a conclusão dos lançamentos contábeis.
Este ponto possui como parâmetro o Array aPedido, que somente terá conteúdo caso o pergunte "Retornar Ped.Venda" esteja igual a "Apto a Faturar".
@type  user function
@author Emerson Nascimento TwoIT
@since 24/08/2025
@version 1.000
@param nil
@return nil
@example
(examples)
@see (links_or_references)
/*/
USER FUNCTION M521DNFS()

Local oFaturmento := Telecontrol.Integracao.Faturamento.TTLCFaturamento():New()

    oFaturmento:Cancela()
    FWFreeObj(@oFaturmento)

RETURN
