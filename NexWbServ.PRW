#INCLUDE "protheus.ch"
//#include 'parmtype.ch'
//#include "TOTVS.CH"
#INCLUDE "restful.ch"
//#include "tbiconn.ch"

#DEFINE NOME_FONTE "NexWbServ.PRW"
#DEFINE compEmpre "01" // juk ver se isso ainda eh util

WSRESTFUL nexSolucoes DESCRIPTION "webService com os metodos da NEX Solucoes" // https://tdn.totvs.com/display/public/framework/02.+Criando+uma+classe+REST https://terminaldeinformacao.com/2024/07/13/criando-um-webservice-rest-com-wsrestful-maratona-advpl-e-tl-535/

	WSMETHOD POST apontamento_producao DESCRIPTION "Endpoint Protheus dedicado a receber e registrar apontamentos de producao" PATH "/production_add"
	WSMETHOD POST saida_produto DESCRIPTION "Endpoint PROTHEUS dedicado a receber faturas que passaram no portal de saída expedição." PATH "/outbound_sell"
	WSMETHOD POST OutTraFil DESCRIPTION "Protheus recebe aviso de saída de produtos com destino a outra filial. Processo disparado na filial de origem." PATH "/transf_fil/out"
	WSMETHOD POST InTraFil DESCRIPTION "Protheus recebe aviso de entrada de produtos na filial de destino. Processo disparado na filial de destino." PATH "/transf_fil/in"
	WSMETHOD POST chamaBlock DESCRIPTION "Endpoint para chamaBlock" PATH "/chamaBlock"

END WSRESTFUL

/*/{Protheus.doc} apontamento_producao
EndPoint para Segel indicar produto produzido
@type user function
@author Julio Carvalho Barberino
@since 09/07/2026
@version 0
@return .T.
/*/
WSMETHOD POST apontamento_producao WSSERVICE nexSolucoes
	local cConteudo		:= self:getContent()
	local oJsonReceb	:= jsonObject():new()
	local cErroJson		:= oJsonReceb:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	local oJsonRet		:= jsonObject():new() // Json de resposta
	local cFilia
	local cOp			// Ordem de producao
	local cCodProd		// Cod do Produto
	local cDescr		// Descricao do produto
	local cArmazem		// Armazem
	local cLote			// Lote
	local nQuant		// Quantidade
	local cSerie		// Numero de serie do produto
	local cTags			// Tags
	local aExecAut		// Array com retorno do execAuto {lOk, cDetalhes}
	local cRet

	self:SetContentType('aplication/json')

	if !empty(cErroJson)
		self:setStatus(400)
		oJsonRet["erro"] := "Erro ao fazer parse do json, erro ao interpretar arquivo json" + cErroJson + " " + NOME_FONTE
		cRet := oJsonRet:toJson()
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(400)
		return .T.
	endIf

	cFilia		:= oJsonReceb:GetJsonObject("filial")
	cOp			:= oJsonReceb:GetJsonObject("op")
	cCodProd	:= oJsonReceb:GetJsonObject("cod_prod")
	cDescr		:= oJsonReceb:GetJsonObject("descricao")
	cArmazem	:= oJsonReceb:GetJsonObject("local")
	cLote		:= oJsonReceb:GetJsonObject("lote")
	nQuant		:= oJsonReceb:GetJsonObject("qtd")
	cSerie		:= oJsonReceb:GetJsonObject("serie")
	cTags		:= oJsonReceb:GetJsonObject("tags")

	BEGIN TRANSACTION
		aExecAut := {.F., "Erro: U_aptProd nÃ£o terminou"}
		aExecAut := U_aptProd(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
		if !aExecAut[1]
			DisarmTransaction()
			oJsonRet["U_aptProd"] := aExecAut[2]
			oJsonRet["retorno"] := "DisarmTransaction() in U_aptProd"
			cRet := oJsonRet:toJson()
			self:setResponse(ENCODEUTF8(cRet))
			self:setStatus(400)
			return .T.
		endIf
		oJsonRet["U_aptProd"] := aExecAut[2]

		aExecAut := {.F., "Erro: U_endereca nÃ£o terminou"}
		aExecAut := U_endereca(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
		if !aExecAut[1]
			DisarmTransaction()
			oJsonRet["U_endereca"] := aExecAut[2]
			oJsonRet["retorno"] := "DisarmTransaction() in U_endereca"
			cRet := oJsonRet:toJson()
			self:setResponse(ENCODEUTF8(cRet))
			self:setStatus(400)
			return .T.
		endIf
		oJsonRet["U_endereca"] := aExecAut[2]
	END TRANSACTION

	oJsonRet["retorno"] := aExecAut[2]
	cRet := oJsonRet:toJson()
	self:setResponse(ENCODEUTF8(cRet))
	self:setStatus(201)
return .T.

/*/{Protheus.doc} saida_produto
EndPoint para Segel indicar saida de produto vendido
@type user function
@author Julio Carvalho Barberino
@since 28/09/2026
@version 0
@return .T.
/*/
WSMETHOD POST saida_produto WSSERVICE nexSolucoes // 1.2.2.2.4.2
	local cConteudo		:= self:getContent()
	local oJsonIn		:= jsonObject():new()
	local cErroJson		:= oJsonIn:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	local oJsonOut		:= jsonObject():new() // Json de resposta
	local nFat, cFilia, cFatura, cFatSerie, cCliente, cProduto, cItem, cTag, nItem

/* Exemplo de json que espera receber
{
  "facturas": [
    {
      "filial": "01",
      "fatura": "0300010035585",
      "fat_serie": "S1",
      "cliente": "1234567890001",
      "itens": [
        {
          "item": "1",
          "pedido": "AACSJW",
          "ordsep": "000006",
          "cod_prod": "ABSNKR100190",
          "lote": "AAEIMA0100",
          "numserie": "000119",
          "qtd": 1,
          "tag": "300862D3D18BE4588BF15F48"
        }
      ]
    }
  ]
}
*/
	dbSelectArea("SD2")
	SD2->(dbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	for nFat := 1 to len(oJsonIn['facturas'])
		cFilia := oJsonIn['facturas'][nFat]['filial']
		cFatura := oJsonIn['facturas'][nFat]['fatura']
		cFatSerie := oJsonIn['facturas'][nFat]['fat_serie']
		cCliente := oJsonIn['facturas'][nFat]['cliente']
		for nItem := 1 to len(oJsonIn['facturas'][nFat]['itens'])
			cProduto := oJsonIn['facturas'][nFat]['itens'][nItem]['cod_prod']
			cItem := oJsonIn['facturas'][nFat]['itens'][nItem]['item']
			cTag := oJsonIn['facturas'][nFat]['itens'][nItem]['tag']
			SD2->(dbGoTop())
			if SD2->(msSeek(cFilia + cFatura + cFatSerie + cCliente + cProduto + cItem))
				recLock("SD2", .F.)
				SD2->D2_ZB0COD := cTag
				SD2->(msUnLock())
			endIf
		next nItem
	next nFat
return .T.

/*/{Protheus.doc} OutTraFil
EndPoint para Segel avisar transferencia de produtos entre filiais (saída)
@type user function
@author Julio Carvalho Barberino
@since 08/10/2026
@version 0
@return .T.
/*/
WSMETHOD POST OutTraFil WSSERVICE nexSolucoes // 1.2.2.2.5.1
	local cConteudo		:= self:getContent()
	local oJsonIn		:= jsonObject():new()
	local cErroJson		:= oJsonIn:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	//local oJsonOut		:= jsonObject():new() // Json de resposta
	local cFilDest		:= oJsonIn['FilDest']
	local cSeriRem		:= "RL "
	local cRem			:= Posicione("SX5", 1, xFilial('SX5') + '01' + cSeriRem, "X5_DESCSPA" )
	local aCab			:= {}
	local aItens		:= {}
	local aItem, nI, cRet, cCodFor, cLojFor
	private lMsErroAuto	:= .F.

/* Exemplo de json que espera receber
{
  "OrdemSaidaNum:": "000154",
  "FilDest": "02",
  "Itens": [
    {
      "CodProd": "0001546",
      "Qtd": 45,
      "Local": "01",
      "Lote": "001546",
      "SerialNumber": "0004687",
      "Endereco": "0048765"
    },
    {
      "CodProd": "0001616",
      "Qtd": 95,
      "Local": "01",
      "Lote": "001547",
      "SerialNumber": "0004688",
      "Endereco": "0048740"
    }
  ]
}
*/
	if !empty(cErroJson)
		cRet := "Erro na interpretacao do json." + CRLF + cErroJson
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(404)
		return .T.
	endIf

	dbSelectArea('SX5')
	dbSetOrder(1)
	SX5->(dbGoTop())
	if !SX5->(msSeek(cFilAnt + "75" + cFilAnt + cEmpAnt + cFilDest)) // https://centraldeatendimento.totvs.com/hc/pt-br/articles/4410465974167-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Abertura-de-ambiente-em-Web-Service https://terminaldeinformacao.com/2025/08/25/como-definir-empresa-e-filial-numa-requisicao-em-rest/ https://centraldeatendimento.totvs.com/hc/es/articles/360007255512-Cross-Segmentos-TOTVS-BackOffice-L%C3%ADnea-Protheus-MI-Stock-y-Costos-SIGAEST-C%C3%B3mo-eliminar-v%C3%ADnculo-entre-Proveedores-vs-Sucursales-del-Sistema
		self:setResponse(ENCODEUTF8("Relacionamento não encontrado na SX5 tabela 75 não encontrado"))
		self:setStatus(404)
		return .T.
	endIf

	cCodFor := subStr(SX5->X5_DESCSPA, 1 /*posicao inicial*/, 15 /*opcional quantidade de caracteres*/)
	cLojFor := subStr(SX5->X5_DESCSPA, 16 /*posicao inicial*/, 2 /*opcional quantidade de caracteres*/)

	dbSelectArea('SA2')
	dbSetOrder(1)
	SA2->(dbGoTop())
	if !SA2->(msSeek(xFilial('SA2') + cCodFor + cLojFor))
		self:setResponse(ENCODEUTF8("Fornecedor não encontrado na SA2"))
		self:setStatus(404)
		return .T.
	endIf

	aAdd(aCab,{"F2_FILIAL",			xFilial("SF2"),		Nil})
	aAdd(aCab,{"F2_FILDEST",		cFilDest,			Nil})
	aAdd(aCab,{"F2_CLIENTE",		SA2->A2_COD,		Nil})
	aAdd(aCab,{"F2_LOJA",			SA2->A2_LOJA,		Nil})
	aAdd(aCab,{"F2_EMISSAO",		dDataBase,			Nil})
	aAdd(aCab,{"F2_SERIE",			cSeriRem,			Nil})
	aAdd(aCab,{"F2_DOC",			cRem,				Nil})
	aAdd(aCab,{"F2_EST",			SA2->A2_EST,		Nil})
	aAdd(aCab,{"F2_TIPO",			"B",				Nil})
	aAdd(aCab,{"F2_ESPECIE",		"RTS",				Nil})
	aAdd(aCab,{"F2_PREFIXO",		"R ",				Nil})
	aAdd(aCab,{"F2_MOEDA",			1,					Nil})
	aAdd(aCab,{"F2_TXMOEDA",		1,					Nil})
	//aAdd(aCab,{"F2_FORMUL",			"S",				Nil})
	aAdd(aCab,{"F2_TIPODOC",		"54",				Nil})
	aAdd(aCab,{"F2_TIPOREM",		"6",				Nil})
	aAdd(aCab,{"F2_TIPORET",		"2",				Nil})
	//aAdd(aCab,{"F2_VEICULO",		"ABC-1234",			Nil})
	//aAdd(aCab,{"F2_NUMTIM",		"15721935",			Nil})
	//aAdd(aCab,{"F2_SERIE2",		"RL",				Nil})
	aCab := FWVetByDic(aCab, "SF2")

	for nI := 1 to len(oJsonIn['Itens'])
		aItem:= {}
		aAdd(aItem,{"D2_COD",			oJsonIn['Itens'][nI]['CodProd'],		Nil})
		aAdd(aItem,{"D2_QUANT",			oJsonIn['Itens'][nI]['Qtd'],			Nil})
		//aAdd(aItem,{"D2_PRCVEN",		38471.36,								Nil})
		//aAdd(aItem,{"D2_TOTAL",			38471.36,								Nil})
		//aAdd(aItem,{"D2_CUSTO1",		38471.36,								Nil})
		//aAdd(aItem,{"D2_TES",			"510",									Nil})
		//aAdd(aItem,{"D2_TESENT",		"013",									Nil})
		//aAdd(aItem,{"D2_UM",			posicione("SB1", 1, fwXFilial("SB1") + oJsonIn['Itens'][nI]['CodProd'], "B1_UM"),	Nil})
		aAdd(aItem,{"D2_ESPECIE",		"RTS",				Nil})
		aAdd(aItem,{"D2_LOCALIZ",		oJsonIn['Itens'][nI]['Endereco'],		Nil})
		aAdd(aItem,{"D2_LOCAL",			oJsonIn['Itens'][nI]['Local'],			Nil})
		aAdd(aItem,{"D2_NUMSERI",		oJsonIn['Itens'][nI]['SerialNumber'],	Nil})
		aAdd(aItem,{"D2_LOTECTL",		oJsonIn['Itens'][nI]['Lote'],			Nil})
		aItem := FWVetByDic(aItem, "SD2")

		aAdd(aItens, aItem)
	next nI

	MSExecAuto( {|x, y, z| Mata462n(x, y, z) }, aCab, aItens, 3)
	if lMsErroAuto
		cRet := MostraErro("MostraErro.txt")
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(406)
	else
		cRet := "Gravou Ok" + CRLF + "Filial: " + fwXFilial("SF2") + "Doc: " + cRem + CRLF + "Serie: " + cSeriRem
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(201)
	EndIf
return .T.

/*/{Protheus.doc} InTraFil
EndPoint para Segel avisar transferencia de produtos entre filiais (entrada)
@type user function
@author Julio Carvalho Barberino
@since 14/10/2026
@version 0
@return .T.
/*/
WSMETHOD POST InTraFil WSSERVICE nexSolucoes
	local cConteudo		:= self:getContent()
	local oJsonIn		:= jsonObject():new()
	local cErroJson		:= oJsonIn:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	//local oJsonOut		:= jsonObject():new() // Json de resposta
	local cFilOri		:= iif(!empty(xFilial('SF2')), padR(oJsonIn['FilOrig'], tamSX3("F2_FILIAL")[1]), padR("", tamSX3("F2_FILIAL")[1]))
	local cDoc			:= padR(oJsonIn['Fatura'], tamSX3("F2_DOC")[1])
	local cDocSeri		:= padR(oJsonIn['FaturaSerie'], tamSX3("F2_SERIE")[1])
	local aCab			:= {}
	local aItens		:= {}
	local aItem, cRet
	private lMsErroAuto	:= .F.
/* Exemplo de json que espera receber
{
  "Fatura": "000258",
  "FaturaSerie": "RL"
  "FilOrig": "01",
  "Itens": [
    {
      "CodProd": "000495",
      "Qtd": 10,
      "SerialNumber": "000632"
    },
    {
      "CodProd": "000496",
      "Qtd": 20,
      "SerialNumber": "000633"
    },
    {
      "CodProd": "000497",
      "Qtd": 30,
      "SerialNumber": "000634"
    }
  ]
}
*/
	if !empty(cErroJson)
		cRet := "Erro na interpretacao do json." + CRLF + cErroJson
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(404)
		return .T.
	endIf

	dbSelectArea('SF2')
	dbSetOrder(1) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	SF2->(dbGoTop())
	if !SF2->(msSeek(cFilOri + cDoc + cDocSeri))
		self:setResponse(ENCODEUTF8("Documento não encontrado na SF2" + CRLF + "Filial: " + cFilOri + " Doc: " + cDoc + "Serie: " + cDocSeri))
		self:setStatus(404)
		return .T.
	endIf

	aAdd(aCab,{"F1_FILIAL",		xFilial("SF1"),			Nil})
	aAdd(aCab,{"F1_TIPO",		"N",					Nil})
	aAdd(aCab,{"F1_FORMUL",		"N" ,					Nil})
	aAdd(aCab,{"F1_DOC",			SF2->F2_DOC,			Nil})
	aAdd(aCab,{"F1_SERIE",		SF2->F2_SERIE,			Nil})
	aAdd(aCab,{"F1_EMISSAO",		SF2->F2_EMISSAO,		Nil})
	aAdd(aCab,{"F1_FORNECE",		SF2->F2_CLIENTE,		Nil})
	aAdd(aCab,{"F1_LOJA",		"01" /*SF2->F2_LOJA*/,	Nil})
	aAdd(aCab,{"F1_TIPODOC",		"64",					Nil})
	aAdd(aCab,{"F1_ESPECIE",		"RTE",					Nil})
	aAdd(aCab,{"F1_EST",			SF2->F2_EST,			Nil})
	aAdd(aCab,{"F1_COND",		SF2->F2_COND,			Nil})
	aAdd(aCab,{"F1_FILORIG",		SF2->F2_FILIAL,			Nil})
	aAdd(aCab,{"F1_SERORIG",		SF2->F2_SERIE,			Nil})
	aAdd(aCab,{"F1_NFORIG",		SF2->F2_DOC,			Nil})
	aAdd(aCab,{"F1_MOEDA",		SF2->F2_MOEDA,			Nil})
	aAdd(aCab,{"F1_TXMOEDA",		SF2->F2_TXMOEDA,		Nil})
	aCab := FWVetByDic( aCab,"SF1" )

	dbSelectArea('SD2')
	dbSetOrder(3) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	SD2->(dbGoTop())
	if !SD2->(msSeek(cFilOri + cDoc + cDocSeri))
		self:setResponse(ENCODEUTF8("Documento não encontrado na SD2" + CRLF + "Filial: " + cFilOri + " Doc: " + cDoc + "Serie: " + cDocSeri))
		self:setStatus(404)
		return .T.
	endIf

	while SD2->D2_DOC == SF2->F2_DOC .and. SD2->D2_SERIE == SF2->F2_SERIE
		aItem:= {}
		aAdd(aItem,{"D1_COD",			SD2->D2_COD,				Nil})
		aAdd(aItem,{"D1_QUANT",			SD2->D2_QUANT,				Nil})
		aAdd(aItem,{"D1_VUNIT",			SD2->D2_PRCVEN,				Nil})
		aAdd(aItem,{"D1_TOTAL",			SD2->D2_TOTAL,				Nil})
		aAdd(aItem,{"D1_TES",			SD2->D2_TESENT,				Nil})
		aAdd(aItem,{"D1_UM",			SD2->D2_UM,					Nil})
		aAdd(aItem,{"D1_TIPODOC",		"64",						Nil})
		aAdd(aItem,{"D1_ESPECIE",		"RTE",						Nil})
		aAdd(aItem,{"D1_LOCAL",			"01" /*juk pode vir de SD2->D2_LOCDEST mas como vai ser quando não tiver saldo inicial?*/,Nil})
		aAdd(aItem,{"D1_NFORI",			SD2->D2_DOC,				Nil})
		aAdd(aItem,{"D1_SERIORI",		SD2->D2_SERIE,				Nil})
		aAdd(aItem,{"D1_ITEMORI",		SD2->D2_ITEM,				Nil})
		aAdd(aItem,{"D1_CUSTO",			SD2->D2_CUSTO1,				Nil})
		aAdd(aItem,{"D1_CUSTO2",		SD2->D2_CUSTO2,				Nil})
		aAdd(aItem,{"D1_LOTECTL",		SD2->D2_LOTECTL,			Nil})
		aAdd(aItem,{"D1_DTVALID",		SD2->D2_DTVALID,			Nil})
		aAdd(aItem,{"D1_NUMSERI",		SD2->D2_NUMSERI,			Nil})
		aAdd(aItem,{"D1_LOCAL",			"P1",						Nil})
		aItem := FWVetByDic( aItem, "SD1" )
		aadd(aItens,aItem)
		SD2->(dbSkip())
	endDo

	MSExecAuto({|v, w, x, y, z| LOCXNF(v, w, x, y, z)}, 64, aCab, aItens, 3, "MATA462TN")
	if lMsErroAuto
		cRet := MostraErro("MostraErro.txt")
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(406)
	else
		cRet := "Gravou Ok" + CRLF + "Filial: " + fwXFilial("SF1") + "Doc: " + cDoc + CRLF + "Serie: " + cDocSeri
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(201)
	EndIf
return .T.

/*/{Protheus.doc} chamaBlock
EndPoint para teste, envio de comandos via REST
@type user function
@author Julio Carvalho Barberino
@since 25/08/2026
@version 0
@return .T.
/*/
WSMETHOD POST chamaBlock WSSERVICE nexSolucoes
	local bBlock
	local aParams
	local cRet			:= "texto qualquer 1522"
	local oJson0		:= jsonObject():new()

	oJson0:fromJson(self:getContent())
	bBlock := &(oJson0['bBlock'])
	aParams := &(oJson0['aParams'])

	if valType(bBlock) == "B" .and. valType(aParams) == "A"
		cRet := cValToChar(eval(bBlock, aParams))
	endIf

	self:setResponse(ENCODEUTF8(cRet))
	self:setStatus(201)
return .T.

/*
	https://terminaldeinformacao.com/2025/08/25/como-definir-empresa-e-filial-numa-requisicao-em-rest/
	https://centraldeatendimento.totvs.com/hc/pt-br/articles/4410465974167-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Abertura-de-ambiente-em-Web-Service
*/
