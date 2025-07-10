#include 'TOTVS.CH'
#include 'RPTDEF.CH'
#include 'FWPrintSetup.ch'

/*/{Protheus.doc} IMG02
@author Sérgio Souza
@since 02/03/2023
@version P12
@description Impressão MIT044 Etiqueta Endereçamento Forest
/*/

User Function IMG02()

    LOCAL _cFont := '040,040' as character
    LOCAL _nLog  as integer
    LOCAL _aLogEti as array

    _aLogEti := &( SuperGetMV("MV_XLOGETI",,'{{"010101","F"},{"020101","R"},{"030101","F"},{"040101","F"},{"050101","F"},{"060101","F"},{"070101","F"},{"080101","R"}}') )

    MSCBChkStatus( .F. )
    MSCBBegin( 1, 6, 50, .F.) /* Inicio da Imagem da Etiqueta */

    _nLog := aScan( _aLogEti, { |x| x[1] == cFilAnt })

    If _aLogEti[ _nLog ][ 2 ] == 'F'

        MSCBLoadGRF("FORESTPA.PCX")    /* carrega imagem transferida para a memória da impressora */ 
        MSCBGrafic(50,000, "FORESTPA") /* impressão da imagem */

    Else

        MSCBLoadGRF("REVITAAM.PCX")    /* carrega imagem transferida para a memória da impressora */
        MSCBGrafic(50,000, "REVITAAM") /* impressão da imagem */ 

    End

    NNR->( MSSeek( FWxFilial('NNR') + SBE->BE_LOCAL, .F.  ))

    MSCBSay(008,010,'ARMAZEM: ' + rtrim(SBE->BE_LOCAL) + ' - ' + rtrim(NNR->NNR_DESCRI),'N','0',_cFont, .F.)
    MSCBLineH(008,016,80,2)
    MSCBSay(008,020,'ENDERECO: '+ rtrim(SBE->BE_LOCALIZ) + ' - ' + rtrim(SBE->BE_DESCRIC) ,'N','0',_cFont, .F.)
    MSCBLineH(008,026,80,2)
    MSCBSAYBAR(005,030,SBE->BE_LOCAL+SBE->BE_LOCALIZ,'N','MB07',12,.F.,.T.,,'B',2.5,2,)

    MSCBEnd()     // Fim da Imagem da Etiqueta

Return( NIL )
