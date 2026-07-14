#INCLUDE "Protheus.ch"
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'parmtype.ch'
#INCLUDE 'Totvs.ch'

#DEFINE senhaChumbadaNofonte '2469' // Coloque aqui a senha que vc deseja antes de compilar
#DEFINE funcaoChubadaNoFonte 'zMiniForm' // Coloque aqui a função que vc deseja executar automáticamente antes de compilar

Static cLogNome := "\system\historico_zMiniForm.log"
Static oLogWrite
Static cLogSepar := "|-|"

Static Function fOK()
	If ALLTRIM(cSenha)<> cSenhAce
		MsgStop('Senha não Confere !!!')
		cSenha := Space(10)
		dlgRefresh(Senhadlg)
	Else
		_lReturn := .T.
		Senhadlg:End()
	Endif
Return

Static Function fDigSenha()
	Private Senhadlg, oGet
	Private cSenha   := Space(20)

	DEFINE DIALOG Senhadlg TITLE OemToAnsi('Liberação de Acesso') FROM 80,80 TO 200,300 PIXEL
	@ 010,010 Say OemToAnsi('Informe a senha para o acesso ?')		Size 150,8 OF Senhadlg PIXEL
	@ 020,010 GET oGet VAR cSenha									SIZE 50,12 OF Senhadlg PIXEL PASSWORD
	@ 040,060 BUTTON 'Ok'											SIZE 30,14 PIXEL ACTION (fOK())
	@ 040,010 BUTTON 'Sair'											SIZE 30,14 PIXEL ACTION Senhadlg:End()
	ACTIVATE DIALOG Senhadlg CENTERED

Return(_lReturn)

user function Chamafun()
	Local cFunc
	Private _lReturn	:= .F.
	Private cSenhAce	:= senhaChumbadaNofonte
	IF !fDigSenha()
		Return
	Endif
	cFunc:=	ALLTRIM(FWInputBox('Digite a User Function que deseja chamar', funcaoChubadaNoFonte))
	IF !Empty(cFunc)
		IF UPPER(LEFT(cFunc,2)) == 'U_'
			cFunc := substr(cFunc,3,len(cFunc)-2)
		ENDIF
		IF ExistBlock(cFunc)
			ExecBlock(cFunc)
		ELSE
			ALERT('User Function' + cFunc + ' não compilada.')
		ENDIF
	else
		MsgStop('Nome de função vazio.' + CRLF + 'Então vai rodar a funcao chubada no fonte.' + CRLF + 'Que no caso é "' + funcaoChubadaNoFonte + '"')
		IF ExistBlock(funcaoChubadaNoFonte)
			ExecBlock(funcaoChubadaNoFonte)
		ELSE
			ALERT('User Function' + funcaoChubadaNoFonte + ' não compilada.')
		ENDIF
	endif
return













/*
	Funções publicadas no site https://terminaldeinformacao.com/2018/02/13/funcao-para-executar-formulas-protheus-12/
*/

/*/{Protheus.doc} zMiniForm
Funcao Mini Formulas, para executar formulas
@author Atilio
@since 17/12/2017
@version 1.0
@type function
@obs Assim como o formulas foi bloqueado no Protheus 12, cuidado ao deixar exposto no menu o Mini Formulas
/*/

User Function zMiniForm()
	Local aArea := GetArea()
	//Variaveis da tela
	Private oDlgForm
	Private oGrpForm
	Private oGetForm
	Private cGetForm := Space(250)
	Private oGrpAco
	Private oBtnExec
	Private oBtnHist
	Private oInibErro, lInibErro := .F.
	//Tamanho da Janela
	Private nJanLarg := 500
	Private nJanAltu := 120
	Private nTamBtn := 048

	//Abre o arquivo de log
	fAbreLog()

	//Criando a janela
	DEFINE MSDIALOG oDlgForm TITLE "zMiniForm - Execucao de Formulas" FROM 000, 000 TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
		//Grupo Formula com o Get
		@ 003, 003 GROUP oGrpForm TO 30, (nJanLarg/2)-1		PROMPT "Formula: " OF oDlgForm COLOR 0, 16777215 PIXEL
			@ 010, 006 MSGET oGetForm VAR cGetForm SIZE (nJanLarg/2)-9, 013 OF oDlgForm COLORS 0, 16777215 PIXEL
		 
		//Grupo Acoes com o Botao
		@ (nJanAltu/2)-30, 003 GROUP oGrpAco TO (nJanAltu/2)-3, (nJanLarg/2)-1 PROMPT "Acoes: " OF oDlgForm COLOR 0, 16777215 PIXEL
			@ (nJanAltu/2)-18, 006 CHECKBOX oInibErro VAR lInibErro PROMPT "Inibe Error Log (utilizar Begin Sequence)" SIZE 200, 010 OF oDlgForm COLORS 0, 16777215 PIXEL
			@ (nJanAltu/2)-24, (nJanLarg/2) - ((nTamBtn*2) + 6) BUTTON oBtnHist PROMPT "Histórico" SIZE nTamBtn, 018 OF oDlgForm ACTION(fHistorico()) PIXEL
			@ (nJanAltu/2)-24, (nJanLarg/2) - ((nTamBtn*1) + 6) BUTTON oBtnExec PROMPT "Executar" SIZE nTamBtn, 018 OF oDlgForm ACTION(fExecuta()) PIXEL
		 
	//Ativando a janela
	ACTIVATE MSDIALOG oDlgForm CENTERED

	//Encerra o arquivo
	fFechaLog()
	 
	RestArea(aArea)
Return

/*---------------------------------------*
| Func.: fExecuta					 |
| Desc.: Executa a formula digitada	 |
*---------------------------------------*/

Static Function fExecuta()
	Local aArea	 := GetArea()
	Local cFormula := Alltrim(cGetForm)
	Local cError	:= ""
	Local bError	:= Nil
	Local cLinhaLog := ""
	Local cCodUsr := RetCodUsr()
	 
	//Se tiver conteudo digitado
	If !Empty(cFormula)
		//Adiciona no log
		cLinhaLog := PadR(cCodUsr,				06) + cLogSepar
		cLinhaLog += PadR(UsrRetName(cCodUsr),	20) + cLogSepar
		cLinhaLog += PadR(GetEnvServer(),		20) + cLogSepar
		cLinhaLog += PadR(dToC(Date()),			10) + cLogSepar
		cLinhaLog += PadR(Time(),				08) + cLogSepar
		cLinhaLog += cFormula
		cLinhaLog += CRLF
		oLogWrite:Write(cLinhaLog)

		//Se tiver habilitado para inibir erros
		If lInibErro
			bError := ErrorBlock({ |oError| cError := oError:Description})

			//Inicio a utilizacao da tentativa
			Begin Sequence
				&(cFormula)
			End Sequence
			 
			//Restaurando bloco de erro do sistema
			ErrorBlock(bError)
			 
			//Se houve erro, sera mostrado ao usuario
			If !Empty(cError)
				MsgStop("Houve um erro na formula digitada: " + CRLF + CRLF + cError, "Atenção")
			EndIf

		//Senão, simplesmente executa a Fórmula conforme ela foi digitada
		Else
			&(cFormula)
		EndIf
	EndIf
	 
	RestArea(aArea)
Return

Static Function fAbreLog()
	Local cLinhaLog := ""
	Local oFile

	//Se o arquivo não existir, terá uma linha de cabeçalho
	If ! File(cLogNome)
		cLinhaLog := PadR("Usr.",			 06) + cLogSepar
		cLinhaLog += PadR("Nome do Usuário", 20) + cLogSepar
		cLinhaLog += PadR("Ambiente",		 20) + cLogSepar
		cLinhaLog += PadR("Data",			 10) + cLogSepar
		cLinhaLog += PadR("Hora",			 08) + cLogSepar
		cLinhaLog += "Fórmula"
		cLinhaLog += CRLF
		cLinhaLog += Replicate("-", 06) + cLogSepar
		cLinhaLog += Replicate("-", 20) + cLogSepar
		cLinhaLog += Replicate("-", 20) + cLogSepar
		cLinhaLog += Replicate("-", 10) + cLogSepar
		cLinhaLog += Replicate("-", 08) + cLogSepar
		cLinhaLog += Replicate("-", Len(cGetForm))
		cLinhaLog += CRLF

	//Senão, faz a leitura do que já existe
	Else
		//Tenta abrir o arquivo e pegar o conteudo
		oFile := FwFileReader():New(cLogNome)
		If oFile:Open()

			//Se deu certo abrir o arquivo, pega o conteudo e exibe
			cLinhaLog := oFile:FullRead()
		EndIf
		oFile:Close()
	EndIf

	//Abre o arquivo
	oLogWrite := FWFileWriter():New(cLogNome, .F.)
	oLogWrite:Create()

	//Se tiver linha, escreve no arquivo
	If ! Empty(cLinhaLog)
		oLogWrite:Write(cLinhaLog)
	EndIf
Return

Static Function fFechaLog()
	oLogWrite:Close()
Return

Static Function fHistorico()
	Local aArea	 := FWGetArea()
	Local cArqLocal := GetTempPath() + "zMiniForm.log"

	//Fecha o log para permitir a cópia
	fFechaLog()

	//Se o arquivo já existir na máquina local, apaga ele
	If File(cArqLocal)
		FErase(cArqLocal)
	EndIf

	//Agora efatua a cópia da Protheus Data para a máquina local
	__CopyFile(cLogNome, cArqLocal)

	//Se o arquivo existir, exibe o conteúdo dele
	If File(cArqLocal)
		ShowMemo(cArqLocal)
	Else
		FWAlertError("Arquivo não encontrado na máquina local!", "Falha")
	EndIf

	//Abre o arquivo de log novamente
	fAbreLog()

	FWRestArea(aArea)
Return
