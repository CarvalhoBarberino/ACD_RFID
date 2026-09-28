#DEFINE NOME_FONTE		"LOCXPE11.prw"
/*
	Punto de entrada que se ejecuta al finalizar la inclusion de la factura de entrada.
	Aqui se utiliza para copiar la informacion del despacho en un campo especifico del
	titulo.
*/
User Function LOCXPE11()
	Local	cDespacho	:=	''//F1_HAWB
	Local	lRet		:=	.T.
	Local	cProv		:=	''
	Local	cLoja		:=	''
	Local	cFact		:=	''
	Local	cSerie		:=	''
	Local	aAreaSF1	:=	GetArea('SF1')
	Local	aAreaSE2	:=	GetArea('SE2')
	Local	aArea		:=	GetArea()
	
	DBSelectArea('SF1')
	cFact	:=	F1_DOC
	cSerie	:=	F1_SERIE
	cProv	:=	F1_FORNECE
	cLoja	:=	F1_LOJA
	cDespacho	:=	F1_HAWB

	DBSelectArea('SE2')
	DBSetOrder(6)
	If DBSeek(xFilial('SE2')+cProv+cLoja+cSerie+cFact)
		While !EOF( ) .and. E2_NUM == cFact .and. E2_PREFIXO == cSerie .and. E2_FORNECE == cProv
			RECLOCK('SE2',.F.)
				E2_UDESPA	:=	cDespacho
			MSUNLOCK()
			DBSkip()
		EndDo
	EndIF

	RestArea( aAreaSF1 )
	RestArea( aAreaSE2 )
	RestArea( aArea )

	if isInCallStack("MATA460B") // Se for chamado pela rotina Documento de saída CARGA
		msgAlert("PE: LOCXPE11" + CRLF + "SF2->F2_DOC " + SF2->F2_DOC)
		if msgYesNo("Confirma o envio de documento fiscal para a Segel?", NOME_FONTE)
			docToSeg(SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE)
		endIf
	endIf
Return
