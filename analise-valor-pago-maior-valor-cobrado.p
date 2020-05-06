/*------------------------------------------------------------------------
    File        : Faturamento.p
    Purpose     :

    Syntax      :

    Description :
           
    Author(s)   :
    Created     : Wed Dec 06 09:17:00 BRST 2017
    Notes       : 
  ----------------------------------------------------------------------*/
/* ***************************  Definitions  ************************** */ 
routine-level on error undo, throw.

define temp-table XML_DOCUMENTO no-undo
    namespace-uri "http://www.thealth.com.br/Document.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_BENEFICIARIO as character 
    field BENEFICIARIO_BASE as logical 
    field CODIGO_UNIDADE_BENEFICIARIO as integer 
    field CODIGO_CARTEIRA_BENEFICIARIO as character 
    index idx1
          CHAVE_SISTEMA. 

define temp-table XML_MOVIMENTO no-undo
    namespace-uri "http://www.thealth.com.br/Document.xsd" 
    field TIPO_MOVIMENTO as integer 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_PRESTADOR_PAGTO as character 
    field CHAVE_SISTEMA_PRESTADOR_EXEC as character 
    field CHAVE_SISTEMA_PROC_INSU as character 
    field QUANTIDADE_COBRADA as decimal 
    field QUANTIDADE_ACEITA as decimal 
    field QUANTIDADE_GLOSADA as decimal 
    field VALOR_GLOSADO_PAGAMENTO as decimal 
    field VALOR_GLOSADO_COBRANCA as decimal 
    field VALOR_PAGO_PRESTADOR as decimal 
    field VALOR_COBRADO_CLIENTE as decimal 
    field VALOR_CALCULADO_SISTEMA as decimal 
    field VALOR_RATEIO as decimal 
    field VALOR_TAXA as decimal 
    field TABELA_PRECO_PAGAMENTO as character 
    field TABELA_PRECO_COBRANCA as character 
    field DT_REALIZACAO as date 
    field DT_CONHECIMENTO as date 
    field COBRADO as logical 
    field CHAVE_SISTEMA_COBRANCA as character 
    field ANO_FATURAMENTO as integer 
    field MES_FATURAMENTO as integer
    field ORIGEM as character  
    field XML_DOCUMENTO_id as recid 
        xml-node-type "HIDDEN" .

define temp-table XML_DADOS_EXTRAS no-undo
    namespace-uri "http://www.thealth.com.br/Document.xsd" 
    field CAMPO as character 
    field VALOR as character 
    field XML_MOVIMENTO_id as recid 
        xml-node-type "HIDDEN" 
    field XML_DOCUMENTO_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_DOCUMENTOS namespace-uri "http://www.thealth.com.br/Document.xsd" 
    for XML_DOCUMENTO, XML_MOVIMENTO, XML_DADOS_EXTRAS
    parent-id-relation RELATION1 for XML_MOVIMENTO, XML_DADOS_EXTRAS
        parent-id-field XML_MOVIMENTO_id
    parent-id-relation RELATION2 for XML_DOCUMENTO, XML_MOVIMENTO
        parent-id-field XML_DOCUMENTO_id
    parent-id-relation RELATION3 for XML_DOCUMENTO, XML_DADOS_EXTRAS
        parent-id-field XML_DOCUMENTO_id.


define variable ORIGEM_PREPAGAMENTO         as   character      init 'PP'  no-undo.
define variable ORIGEM_CUSTOOPERACIONAL     as   character      init 'CO'  no-undo.
define variable ORIGEM_INTERCAMBIO          as   character      init 'IN'  no-undo.
     
/*------------------------------------------------------------------------
    File        : ExecutaFonteProgress.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Dec 15 13:37:24 BRST 2017
    Notes       : 
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/*------------------------------------------------------------------------
    File        : erro.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Apr 26 11:31:43 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function DispararException returns logical 
        (ch-descricao-erro             as   character,
         in-codigo-erro                as   integer) forward.


/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function DispararException returns logical 
        (ch-descricao-erro             as   character,
         in-codigo-erro                as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    log-manager:write-message (substitute ('&1', ch-descricao-erro ),'ERROR').    
    undo, throw new Progress.Lang.AppError(ch-descricao-erro, in-codigo-erro).
    
                
end function.

 

/*------------------------------------------------------------------------
    File        : files.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Apr 26 14:51:46 BRT 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/*------------------------------------------------------------------------
    File        : files_inc.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon May 08 19:10:33 GMT-03:00 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-arquivo-diretorio    no-undo
    field ch-nome-arquivo                   as   character
    field ch-nome-arquivo-sem-extensao      as   character 
    field ch-extensao-arquivo               as   character
    field ch-caminho-completo-arquivo       as   character
    index idx1
          ch-nome-arquivo
    index idx2
          ch-nome-arquivo-sem-extensao.
 

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function ArquivoExiste returns logical 
        (ch-caminho-arquivo        as   character) forward.

function CriarDiretorio returns character 
        (ch-caminho            as   character) forward.

function GerarArquivoTemporario returns character 
        (ch-extensao           as   character) forward.

function GerarNomeArquivoTemporario returns character 
        (ch-extensao           as   character) forward.
        
function LeConteudoArquivo returns longchar 
    (ch-path          as   character,
     ch-source-encode as   character,
     ch-target-encode as   character) forward.

function ListarArquivosDiretorio returns logical 
        (ch-diretorio          as   character,
         ch-extensao           as   character) forward.

/* ***************************  Main Block  *************************** */


/* ************************  Function Implementations ***************** */

function ArquivoExiste returns logical 
        (ch-caminho-arquivo        as   character  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    file-info:file-name = ch-caminho-arquivo.
    
    return file-info:full-pathname <> ?.
                
end function.

function CriarDiretorio returns character 
        (ch-caminho            as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    os-create-dir value (ch-caminho).
    
end function.

function GerarArquivoTemporario returns character 
        (ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    define variable ch-nome-arquivo-unico   as   character  no-undo.
    
    assign ch-nome-arquivo-unico   = session:temp-directory
           ch-nome-arquivo-unico   = substitute ("&1/&2", ch-nome-arquivo-unico, GerarNomeArquivoTemporario(ch-extensao)).
    
    return ch-nome-arquivo-unico.    
end function.

function GerarNomeArquivoTemporario returns character 
        (ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    define variable rw-unique-id            as   raw        no-undo.
    define variable ch-guid                 as   character  no-undo.

    assign rw-unique-id = generate-uuid
           ch-guid      = guid(rw-unique-id). 
    return replace (replace (ch-guid, "-", ""), ".", "") + "." + ch-extensao.           
end function.

function ListarArquivosDiretorio returns logical 
        (ch-diretorio          as   character,
         ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
----------------------------------------------- -------------------------------*/       
    define variable hd-programa             as   handle         no-undo.
    
    if not valid-handle (hd-programa) then run utils/files.p persistent set hd-programa.
        
    run ListarArquivosDiretorio in hd-programa (input ch-diretorio, input ch-extensao, input-output table temp-arquivo-diretorio).
    
end function.

function LeConteudoArquivo returns longchar 
    (input ch-path          as   character,
     input ch-source-encode as   character,
     input ch-target-encode as   character):

    define variable ch-content      as   longchar.
    define variable ch-line         as   character.
    
    if  ch-source-encode   <> ?
    and ch-target-encode   <> ?
    then do:
        input from value (ch-path) convert source ch-source-encode target ch-target-encode.
    end.
    else input from value (ch-path).
    
    repeat:
        import unformatted ch-line.
        if (ch-content  = "")
        then do:
            ch-content  = ch-line.
        end.
        else do:
            ch-content = ch-content + chr(13) + ch-line.
        end.
    end.
    input close.
    
    return ch-content.
end function.        

 

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-parametro-entrada        no-undo
    field in-id-execucao                        as   integer
    field ch-nome-programa                      as   character
    field ch-modo                               as   character
    field ch-parametros                         as   character
    field in-qt-dias                            as   integer
    field ch-modo-envio-dados                   as   character
    field ch-caminho-gravacao-arquivos          as   character
    field dt-qt-dias                            as   datetime
    field lg-parametros-periodos                as   logical    init no.
    
define temp-table temp-parametro-periodo        no-undo
    field in-ano                                as   integer
    field in-mes                                as   integer
    index idx1
          as primary as unique
          in-ano
          in-mes.    
    
define temp-table XML_EXECUCAO no-undo
    namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    field ID_EXECUCAO as integer 
    field INICIO as datetime-tz 
    field FIM as datetime-tz 
    field OCORREU_ERRO as logical .

define temp-table XML_ERRO no-undo
    namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    field CODIGO as integer 
    field MENSAGEM as character 
    field XML_EXECUCAO_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_EXECUCAODset namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    xml-node-type "HIDDEN" 
    for XML_EXECUCAO, XML_ERRO
    parent-id-relation RELATION1 for XML_EXECUCAO, XML_ERRO
        parent-id-field XML_EXECUCAO_id.



    
define temp-table temp-base-comunicacao         no-undo
    field ch-chave-sistema                      as   character  xml-node-name 'CHAVE_SISTEMA'.
    
define variable MODO_EXECUCAO_TOTAL             as   character  init 'TOTAL'    no-undo.
define variable MODO_EXECUCAO_PARCIAL           as   character  init 'PARCIAL'  no-undo.

define variable ENVIAR_DADOS_WEBSERVICE         as   character  init 'WEBSERVICE'   no-undo.
define variable ENVIAR_DADOS_ARQUIVO            as   character  init 'ARQUIVO'   no-undo.
    
define new global shared variable hd-web-service                  as   handle                     no-undo.
define new global shared variable hd-progress-service             as   handle                     no-undo.

// Tabela que armazena as requisiá‰es assincronas dos webservices. Tem por finalidade apenas n∆o destruir o handle da requisiá∆o para que o resultado possa ser processado

define temp-table temp-request-handlers         no-undo
    field hd-request as handle .

function ChamaWebServiceRetorno returns character 
    (in-task-id                         as   integer,
     lo-xml                             as   longchar) forward.

function EnviarDados returns logical 
    (hd-dataset             as   handle) forward.

function FinalizarTarefa returns character 
    (in-id-task                     as   integer) forward.

/* ************************  Function Prototypes ********************** */

function ReportarError returns character 
    (in-task-id                         as   integer) forward.

function ConverteData returns date 
    (ch-valor           as   character) forward.

function PreparaWebService returns character 
    (  ) forward.

function RegistroPrimary returns character 
    (input hd-temp-table    as handle) forward.
    
function ConverteTempParaXml returns longchar 
    (hd-table-handle           as   handle) forward.    

/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function ReportarError returns character 
    (in-task-id                         as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable ch-resposta         as   character  init '' no-undo.
    define variable ch-nome-arquivo     as   character  init '' no-undo.
    define variable lg-xml              as   logical            no-undo.
    define variable lo-xml              as   longchar           no-undo.

    find first temp-parametro-entrada.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        PreparaWebService().
        
        assign lo-xml   = ConverteTempParaXml (dataset XML_EXECUCAODset:handle).
        
        run ReportarErroEtapa in hd-progress-service (input in-task-id, input lo-xml) no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel realizar a chamada EnviarDadosTarefa: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
    
        end.
    end.
    else do:
        
        assign ch-nome-arquivo  = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, '.error').
        lg-xml = dataset XML_EXECUCAODset:write-xml('file', ch-nome-arquivo, false, 'ISO8859-1', ?, false, false) no-error.
        if not lg-xml
        or error-status:error
        then do:
            log-manager:write-message (substitute ('erro: ', error-status:get-message (1)),'ERROR').            
        end.
    end.
end function.

function ConverteData returns date 
    (ch-valor           as   character  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    define variable dt-convertida   as   date       no-undo.
    
    assign dt-convertida = date (integer (entry (2, ch-valor, '/')),
                                 integer (entry (3, ch-valor, '/')),
                                 integer (entry (1, ch-valor, '/'))) no-error.
                      
    if error-status:error
    then return ?.        
    
    return dt-convertida.
        
end function.

function PreparaWebService returns character 
    (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    
    if not valid-handle (hd-web-service)
    then do:
        create server hd-web-service.
    end.
     
    if not hd-web-service:connected ()
    then do:
        hd-web-service:connect ("-WSDL 'http://localhost:7640/Progress?wsdl'") no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel conectar ao webservice: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
        end.
    end.
    
    if not valid-handle (hd-progress-service)
    then do:
        run Progress set hd-progress-service on hd-web-service no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel criar o handle do Progress: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
    
        end.        
    end.

        
end function.


function RegistroPrimary returns character 
    (input hd-temp-table    as handle):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
        
    define variable ch-keys         as character    no-undo.
    define variable in-num-keys     as integer      no-undo.
    define variable in-index        as integer      no-undo.
    define variable ch-holder       as character    no-undo.
    define variable ch-valor        as character    no-undo.

    assign ch-keys = hd-temp-table:keys(1).    
    if ch-keys = "rowid" then return "".
        
    assign in-num-keys = num-entries (ch-keys, ",").
    do in-index = 1 to in-num-keys:
        assign ch-valor = hd-temp-table:buffer-field (entry (in-index, ch-keys, ",")):buffer-value no-error.
        if not error-status:error
        then do:
            if ch-holder <> '' then ch-holder = ch-holder + ':'.
            ch-holder = ch-holder + substitute ("&1", ch-valor).
        end.        
    end.    
    return ch-holder.
        
end function.              

function ChamaWebServiceRetorno returns character 
    (in-task-id                         as   integer,
     lo-xml                             as   longchar ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    
end function.



/* **********************  Internal Procedures  *********************** */
procedure HandleProcedureReturn:    
    define input parameter dt-e             as   datetime       no-undo.
        
    log-manager:write-message(substitute ('hora do termino da requisiá∆o: &1', dt-e)).
    process events.   
end procedure.



function EnviarDados returns logical 
    (hd-dataset             as   handle  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable lo-xml                  as   longchar           no-undo.
    define variable ch-erro-webservice      as   character          no-undo.
    define variable ch-nome-arquivo         as   character          no-undo.
    define variable lg-erro-escrita-xml     as   logical            no-undo.
    define variable ch-resposta             as   character  init '' no-undo.
    define variable hd-request              as   handle             no-undo.
    define variable dt-output               as   datetime           no-undo.
    
    find first temp-parametro-entrada.       
    log-manager:write-message (substitute ('modo de comunicaá∆o: &1', temp-parametro-entrada.ch-modo-envio-dados ),'DEBUG') no-error.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        log-manager:write-message (substitute ('enviando registros via webservice'),'DEBUG') no-error.
        
        assign lo-xml   = ConverteTempParaXml(hd-dataset).

        PreparaWebService().
        
        log-manager:write-message (substitute ('verificando quantidade de requisicoes abertas: &1', hd-web-service:async-request-count),'DEBUG') no-error.
        do while hd-web-service:async-request-count > 5:
            pause 1.
            process events.
        end.
        
        log-manager:write-message (substitute ('enviando dados ao webservice' ),'DEBUG') no-error.            
        run EnviarDadosEtapa in hd-progress-service 
                             asynchronous set hd-request 
                             event-procedure 'HandleProcedureReturn' (input temp-parametro-entrada.in-id-execucao, 
                                                                      input lo-xml, 
                                                                      output dt-output) no-error.
        if error-status:error
        then do:
            DispararException (substitute ('nao foi possivel realizar a chamada EnviarDadosTarefa: &1 - &2',
                                           error-status:get-number (1),
                                           error-status:get-message (1)), 0).
        end.
        // armazena na temp-table o handle da requisicao para que o objeto nao seja destruido e possa processasr o retorno. caso os handles sejam destruidos, 

        // a property hd-web-service:async-request-count nunca ser† atualizada com o resultado dos processamentos.

        create temp-request-handlers.
        assign temp-request-handlers.hd-request = hd-request.
        
    end.
    else do:
        log-manager:write-message (substitute ('enviando dados via arquivo' ),'DEBUG') no-error.
         
        
        assign ch-nome-arquivo = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, GerarNomeArquivoTemporario("xml")).
        
        log-manager:write-message (substitute ('nome do arquivo: &1', ch-nome-arquivo ),'DEBUG') no-error.
        
        lg-erro-escrita-xml = hd-dataset:write-xml('file', ch-nome-arquivo, false, 'ISO8859-1', ?, false, false) no-error.
        
        if not lg-erro-escrita-xml 
        or error-status:error
        then do:
            DispararException (substitute ('erro ao escrever xml: &1', error-status:get-message (1)), 0).
        end.
    end.
    return yes.
end function.

function ConverteTempParaXml returns longchar 
    (hd-table-handle           as   handle):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable result as longchar no-undo.
    
    log-manager:write-message (substitute ('convertendo temp/dataset para xml '),'DEBUG') no-error.
       
    hd-table-handle:write-xml ("longchar",
                               result,
                               no, 
                               session:cpinternal,
                               ?,
                               no,
                               no).
    return result.
end function.



function FinalizarTarefa returns character 
    (in-id-task                     as   integer  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    define variable ch-resposta         as   character  no-undo.
    define variable lg-ok               as   logical    no-undo.
    define variable lo-xml              as   longchar   no-undo.

    find first temp-parametro-entrada.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        
        PreparaWebService().    
            
        do while hd-web-service:async-request-count > 0:
            pause 1.
            process events.
        end.
        
        assign lo-xml   = ConverteTempParaXml (dataset XML_EXECUCAODset:handle).
        
        run ReportarFinalizacaoEtapa in hd-progress-service (input  in-id-task,
                                                             input  lo-xml) no-error.
        if error-status:error
        then do:
            DispararException (substitute ('nao foi possivel realizar a chamada FinishTask: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)), 0).
        end.
          
        hd-web-service:disconnect () no-error. 
        delete object hd-progress-service no-error.
        delete object hd-web-service no-error.
    end.
    else do: 
        
        define variable ch-nome-arquivo as   character  no-undo.
        
        assign ch-nome-arquivo  = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, '.finish').
        output to value(ch-nome-arquivo).
            put skip.
        output close.
    end.
    

        
end function. 
    

/* **********************  Internal Procedures  *********************** */

define variable TIPO_MOVIMENTO_INSUMO           as   integer    init '1'    no-undo.
define variable TIPO_MOVIMENTO_PROCEDIMENTO     as   integer    init '0'    no-undo.



/* ************************  Function Prototypes ********************** */
function ObtemOrigem returns character 
    (in-unidade-carteira    as   integer,
     in-modalidade          as   integer,
     in-termo-adesao        as   integer) forward.

procedure AnalisaInsumo:
    define input-output parameter in-conta          as   integer        no-undo.
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable dc-valor-real-pago              as   decimal        no-undo.
    define variable dc-valor-glosa                  as   decimal        no-undo.
    define variable in-qt-glosa                     as   integer        no-undo.
    
    define buffer buf-preserv                       for  preserv.

    find first mov-insu no-lock
     use-index mov-ins1 
         where mov-insu.cd-unidade              = fateveco.cd-unidade
           and mov-insu.cd-unidade-prestadora   = fateveco.cd-unidade-prestador
           and mov-insu.cd-transacao            = fateveco.cd-transacao
           and mov-insu.nr-serie-doc-original   = fateveco.nr-serie-doc-original
           and mov-insu.nr-doc-original         = fateveco.nr-doc-original
           and mov-insu.nr-doc-sistema          = fateveco.nr-doc-sistema
           and mov-insu.nr-processo             = fateveco.nr-processo
           and mov-insu.nr-seq-digitacao        = fateveco.nr-seq-digitacao
               no-error.
               
    if not available mov-insu
    then do:
        return.        
    end.
    
    if  mov-insu.cd-tipo-pagamento <> 0
    then return.         
               
    if mov-insu.vl-real-pago    > 0
    then dc-valor-real-pago = mov-insu.vl-real-pago.
    else dc-valor-real-pago = mov-insu.vl-insumo.      
        
    if fateveco.vl-contas  >= dc-valor-real-pago
    then return.      
    
    find first docrecon no-lock
     use-index docreco1
         where docrecon.cd-unidade              = mov-insu.cd-unidade
           and docrecon.cd-unidade-prestadora   = mov-insu.cd-unidade-prestadora
           and docrecon.cd-transacao            = mov-insu.cd-transacao         
           and docrecon.nr-serie-doc-original   = mov-insu.nr-serie-doc-original
           and docrecon.nr-doc-original         = mov-insu.nr-doc-original      
           and docrecon.nr-doc-sistema          = mov-insu.nr-doc-sistema
               no-error.
    
    if not available docrecon
    then do:
        return.            
    end.                       
        
    find first insumos no-lock
     use-index insumo1
         where insumos.cd-tipo-insumo   = mov-insu.cd-tipo-insumo 
           and insumos.cd-insumo        = mov-insu.cd-insumo
               no-error.

    if not available insumos
    then do:
        return.           
    end.    
    
    find first XML_DOCUMENTO 
         where XML_DOCUMENTO.CHAVE_SISTEMA  = RegistroPrimary(buffer docrecon:handle)
               no-error.

    if not available XML_DOCUMENTO
    then do:
        
        if docrecon.cd-unidade-carteira = paramecp.cd-unimed
        then do:
            find first usuario no-lock
                 where usuario.cd-modalidade        = docrecon.cd-modalidade
                   and usuario.nr-ter-adesao        = docrecon.nr-ter-adesao
                   and usuario.cd-usuario           = docrecon.cd-usuario
                       no-error.
        end.
        
        create XML_DOCUMENTO.
        assign in-conta                         = in-conta + 1
               XML_DOCUMENTO.CHAVE_SISTEMA      = RegistroPrimary(buffer docrecon:handle)
               XML_DOCUMENTO.CHAVE_SISTEMA_BENEFICIARIO 
                                                = if available usuario then RegistroPrimary (buffer usuario:handle) else ''
               XML_DOCUMENTO.CODIGO             = substitute ('&1/&2/&3/&4/&5/&6',
                                                              docrecon.cd-unidade,
                                                              docrecon.cd-unidade-prestadora,
                                                              docrecon.cd-transacao,
                                                              docrecon.nr-serie-doc-original,
                                                              docrecon.nr-doc-original,
                                                              docrecon.nr-doc-sistema)
               XML_DOCUMENTO.BENEFICIARIO_BASE  = if docrecon.cd-unidade-carteira = paramecp.cd-unimed then yes else no
               XML_DOCUMENTO.CODIGO_UNIDADE_BENEFICIARIO
                                                = docrecon.cd-unidade-carteira
               XML_DOCUMENTO.CODIGO_CARTEIRA_BENEFICIARIO
                                                = string (docrecon.cd-carteira-usuario).
                                                
    end.
           
    find first preserv no-lock
     use-index preserv1
         where preserv.cd-unidade   = mov-insu.cd-unidade-pagamento
           and preserv.cd-prestador = mov-insu.cd-prestador-pagamento
               no-error.

    find first buf-preserv no-lock
     use-index preserv1
         where buf-preserv.cd-unidade   = mov-insu.cd-unidade-prestador
           and buf-preserv.cd-prestador = mov-insu.cd-prestador
               no-error.

    run BuscaValorGlosadoInsumo (output dc-valor-glosa,
                                 output in-qt-glosa).
               
    create XML_MOVIMENTO.
    assign XML_MOVIMENTO.XML_DOCUMENTO_id               = recid(XML_DOCUMENTO)
           XML_MOVIMENTO.TIPO_MOVIMENTO                 = TIPO_MOVIMENTO_INSUMO
           XML_MOVIMENTO.CHAVE_SISTEMA                  = 'I' + RegistroPrimary (buffer mov-insu:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PRESTADOR_PAGTO  = RegistroPrimary (buffer preserv:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PRESTADOR_EXEC   = RegistroPrimary (buffer buf-preserv:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PROC_INSU        = RegistroPrimary (buffer insumos:handle) 
           XML_MOVIMENTO.QUANTIDADE_COBRADA             = mov-insu.qt-cobrado
           XML_MOVIMENTO.QUANTIDADE_ACEITA              = mov-insu.qt-insumo - in-qt-glosa
           XML_MOVIMENTO.QUANTIDADE_GLOSADA             = in-qt-glosa
           XML_MOVIMENTO.VALOR_PAGO_PRESTADOR           = dc-valor-real-pago
           XML_MOVIMENTO.VALOR_GLOSADO_PAGAMENTO        = dc-valor-glosa
           XML_MOVIMENTO.VALOR_CALCULADO_SISTEMA        = mov-insu.vl-base-valor-sistema
           XML_MOVIMENTO.VALOR_COBRADO_CLIENTE          = fateveco.vl-contas
           XML_MOVIMENTO.VALOR_RATEIO                   = mov-insu.vl-rateio-prestador
           XML_MOVIMENTO.VALOR_TAXA                     = fateveco.vl-evento - fateveco.vl-contas   
           XML_MOVIMENTO.TABELA_PRECO_PAGAMENTO         = string (mov-insu.cd-tab-preco-proc, 'xxx/99')
           XML_MOVIMENTO.TABELA_PRECO_COBRANCA          = string (mov-insu.cd-tab-preco-proc-cob, 'xxx/99')
           XML_MOVIMENTO.DT_REALIZACAO                  = mov-insu.dt-realizacao
           XML_MOVIMENTO.DT_CONHECIMENTO                = if mov-insu.date-3 = ?
                                                          then mov-insu.dt-digitacao
                                                          else mov-insu.date-3
           XML_MOVIMENTO.ORIGEM                         = ObtemOrigem (mov-insu.cd-unidade-carteira,
                                                                       mov-insu.cd-modalidade,
                                                                       mov-insu.nr-ter-adesao)                                                          
           XML_MOVIMENTO.COBRADO                        = yes
           XML_MOVIMENTO.ANO_FATURAMENTO                = fatura.aa-referencia
           XML_MOVIMENTO.MES_FATURAMENTO                = fatura.mm-referencia   
           XML_MOVIMENTO.CHAVE_SISTEMA_COBRANCA         = RegistroPrimary (buffer notaserv:handle).
           
    create XML_DADOS_EXTRAS.
    assign XML_DADOS_EXTRAS.CAMPO               = "Tabela Moeda/Carància Pagamento"
           XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-tab-preco, "999/99")
           XML_DADOS_EXTRAS.XML_MOVIMENTO_id    = recid (XML_MOVIMENTO).
    create XML_DADOS_EXTRAS.
    assign XML_DADOS_EXTRAS.CAMPO               = "Tabela Moeda/Carància Cobranáa"
           XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-tab-preco-cob, "999/99")
           XML_DADOS_EXTRAS.XML_MOVIMENTO_id    = recid (XML_MOVIMENTO).
                 

end procedure.

procedure AnalisaProcedimento:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input-output parameter in-conta          as   integer        no-undo.

    define variable dc-valor-real-pago              as   decimal        no-undo.
    define variable dc-valor-glosa                  as   decimal        no-undo.
    define variable in-qt-glosa                     as   integer        no-undo.
    define buffer buf-preserv                       for  preserv.
    
    find first moviproc no-lock
     use-index movipro1 
         where moviproc.cd-unidade              = fateveco.cd-unidade
           and moviproc.cd-unidade-prestadora   = fateveco.cd-unidade-prestador
           and moviproc.cd-transacao            = fateveco.cd-transacao
           and moviproc.nr-serie-doc-original   = fateveco.nr-serie-doc-original
           and moviproc.nr-doc-original         = fateveco.nr-doc-original
           and moviproc.nr-doc-sistema          = fateveco.nr-doc-sistema
           and moviproc.nr-processo             = fateveco.nr-processo
           and moviproc.nr-seq-digitacao        = fateveco.nr-seq-digitacao
               no-error.
                              
    if not available moviproc
    then do:
        return.
    end.                  
    
    if  moviproc.cd-tipo-pagamento <> 0
    then return.         
               
    if moviproc.vl-real-pago    > 0 
    then dc-valor-real-pago = moviproc.vl-real-pago.
    else dc-valor-real-pago = moviproc.vl-principal + moviproc.vl-auxiliar.      
    
    if fateveco.vl-contas  >= dc-valor-real-pago
    then return.      
    
    find first docrecon no-lock
     use-index docreco1
         where docrecon.cd-unidade              = moviproc.cd-unidade
           and docrecon.cd-unidade-prestadora   = moviproc.cd-unidade-prestadora
           and docrecon.cd-transacao            = moviproc.cd-transacao         
           and docrecon.nr-serie-doc-original   = moviproc.nr-serie-doc-original
           and docrecon.nr-doc-original         = moviproc.nr-doc-original      
           and docrecon.nr-doc-sistema          = moviproc.nr-doc-sistema
               no-error.
    
    if not available docrecon
    then do:
        return.                              
    end.                
    
    find first ambproce no-lock
     use-index ambproc1 
         where ambproce.cd-esp-amb          = moviproc.cd-esp-amb
           and ambproce.cd-grupo-proc-amb   = moviproc.cd-grupo-proc-amb
           and ambproce.cd-procedimento     = moviproc.cd-procedimento
           and ambproce.dv-procedimento     = moviproc.dv-procedimento
               no-error.
               
    if not available ambproce
    then do:
        return. 
    end.                          
                                  
    find first XML_DOCUMENTO 
         where XML_DOCUMENTO.CHAVE_SISTEMA  = RegistroPrimary(buffer docrecon:handle)
               no-error.

    if not available XML_DOCUMENTO
    then do:
        
        if docrecon.cd-unidade-carteira = paramecp.cd-unimed
        then do:
            
            find first usuario no-lock
                 where usuario.cd-modalidade        = docrecon.cd-modalidade
                   and usuario.nr-ter-adesao        = docrecon.nr-ter-adesao
                   and usuario.cd-usuario           = docrecon.cd-usuario
                       no-error.
        end.
        
        create XML_DOCUMENTO.
        assign in-conta                         = in-conta + 1
               XML_DOCUMENTO.CHAVE_SISTEMA      = RegistroPrimary(buffer docrecon:handle)
               XML_DOCUMENTO.CHAVE_SISTEMA_BENEFICIARIO 
                                                = if available usuario then RegistroPrimary (buffer usuario:handle) else ''
               XML_DOCUMENTO.CODIGO             = substitute ('&1/&2/&3/&4/&5/&6',
                                                              docrecon.cd-unidade,
                                                              docrecon.cd-unidade-prestadora,
                                                              docrecon.cd-transacao,
                                                              docrecon.nr-serie-doc-original,
                                                              docrecon.nr-doc-original,
                                                              docrecon.nr-doc-sistema)
               XML_DOCUMENTO.BENEFICIARIO_BASE  = if docrecon.cd-unidade-carteira = paramecp.cd-unimed then yes else no
               XML_DOCUMENTO.CODIGO_UNIDADE_BENEFICIARIO
                                                = docrecon.cd-unidade-carteira
               XML_DOCUMENTO.CODIGO_CARTEIRA_BENEFICIARIO
                                                = string (docrecon.cd-carteira-usuario).
    end.
    
    find first preserv no-lock
     use-index preserv1
         where preserv.cd-unidade   = moviproc.cd-unidade-pagamento
           and preserv.cd-prestador = moviproc.cd-prestador-pagamento
               no-error.

    find first buf-preserv no-lock
     use-index preserv1
         where buf-preserv.cd-unidade   = moviproc.cd-unidade-prestador
           and buf-preserv.cd-prestador = moviproc.cd-prestador
               no-error.
               
    run BuscaValorGlosadoProcedimento (output dc-valor-glosa,
                                       output in-qt-glosa).
               
    create XML_MOVIMENTO.
    assign XML_MOVIMENTO.XML_DOCUMENTO_id               = recid(XML_DOCUMENTO)
           XML_MOVIMENTO.TIPO_MOVIMENTO                 = TIPO_MOVIMENTO_PROCEDIMENTO
           XML_MOVIMENTO.CHAVE_SISTEMA                  = 'P' + RegistroPrimary (buffer moviproc:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PRESTADOR_PAGTO  = RegistroPrimary (buffer preserv:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PRESTADOR_EXEC   = RegistroPrimary (buffer buf-preserv:handle)
           XML_MOVIMENTO.CHAVE_SISTEMA_PROC_INSU        = RegistroPrimary (buffer ambproce:handle)
           XML_MOVIMENTO.QUANTIDADE_COBRADA             = moviproc.qt-cobrado
           XML_MOVIMENTO.QUANTIDADE_ACEITA              = moviproc.qt-procedimentos - in-qt-glosa
           XML_MOVIMENTO.QUANTIDADE_GLOSADA             = in-qt-glosa
           XML_MOVIMENTO.VALOR_PAGO_PRESTADOR           = dc-valor-real-pago
           XML_MOVIMENTO.VALOR_GLOSADO_PAGAMENTO        = dc-valor-glosa
           XML_MOVIMENTO.VALOR_CALCULADO_SISTEMA        = moviproc.vl-base-valor-sistema
           XML_MOVIMENTO.VALOR_COBRADO_CLIENTE          = fateveco.vl-contas 
           XML_MOVIMENTO.VALOR_RATEIO                   = moviproc.vl-rateio-prestador
           XML_MOVIMENTO.VALOR_TAXA                     = fateveco.vl-evento - fateveco.vl-contas   
           XML_MOVIMENTO.TABELA_PRECO_PAGAMENTO         = string (moviproc.cd-tab-preco-proc, 'xxx/99')
           XML_MOVIMENTO.TABELA_PRECO_COBRANCA          = string (moviproc.cd-tab-preco-proc-cob, 'xxx/99')
           XML_MOVIMENTO.DT_REALIZACAO                  = moviproc.dt-realizacao
           XML_MOVIMENTO.DT_CONHECIMENTO                = if moviproc.date-3 = ? 
                                                          then moviproc.dt-digitacao
                                                          else moviproc.date-3
           XML_MOVIMENTO.COBRADO                        = yes           
           XML_MOVIMENTO.ORIGEM                         = ObtemOrigem (moviproc.cd-unidade-carteira,
                                                                       moviproc.cd-modalidade,
                                                                       moviproc.nr-ter-adesao)                     
           XML_MOVIMENTO.ANO_FATURAMENTO                = fatura.aa-referencia
           XML_MOVIMENTO.MES_FATURAMENTO                = fatura.mm-referencia
           XML_MOVIMENTO.CHAVE_SISTEMA_COBRANCA         = RegistroPrimary (buffer notaserv:handle).
           
    create XML_DADOS_EXTRAS.
    assign XML_DADOS_EXTRAS.CAMPO               = "Tabela Moeda/Carància Pagamento"
           XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-tab-preco, "999/99")
           XML_DADOS_EXTRAS.XML_MOVIMENTO_id    = recid (XML_MOVIMENTO).
    
    create XML_DADOS_EXTRAS.
    assign XML_DADOS_EXTRAS.CAMPO               = "Tabela Moeda/Carància Cobranáa"
           XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-tab-preco-cob, "999/99")
           XML_DADOS_EXTRAS.XML_MOVIMENTO_id    = recid (XML_MOVIMENTO).
                   

end procedure.

procedure BuscaValorGlosadoInsumo:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define output   parameter dc-valor-glosa            as   decimal    no-undo.
    define output   parameter in-qt-glosa               as   integer    no-undo.
    
    define variable lg-tem-glosa-quantitativo           as   logical    no-undo.
    define variable lg-tem-outras-glosas                as   logical    no-undo.
    define variable lg-tem-glosa-fracionamento          as   logical    no-undo.
    define variable in-qt-glosado                       as   integer    no-undo.   
    define variable vl-glosado-par                      as   decimal    no-undo.    
    define variable vl-movto                            as   decimal    no-undo.         
                   
    /* ---- GRAVACAO DO RESUMO DE PROCEDIMENTOS GLOSADOS ---- */
    if  mov-insu.cd-cod-glo   <> 0
    then do:
        
        for each movrcglo no-lock
       use-index movrcgl1
           where movrcglo.cd-unidade            = mov-insu.cd-unidade
             and movrcglo.cd-unidade-prestadora = mov-insu.cd-unidade-prestadora
             and movrcglo.cd-transacao          = mov-insu.cd-transacao
             and movrcglo.nr-serie-doc-original = mov-insu.nr-serie-doc-original
             and movrcglo.nr-doc-original       = mov-insu.nr-doc-original
             and movrcglo.nr-doc-sistema        = mov-insu.nr-doc-sistema
             and movrcglo.nr-processo           = mov-insu.nr-processo
             and movrcglo.nr-seq-digitacao      = mov-insu.nr-seq-digitacao:

            find first codiglos no-lock
             use-index codiglo1
                 where codiglos.cd-cod-glo  = movrcglo.cd-cod-glo
                   and codiglos.dt-limite  >= mov-insu.dt-realizacao
                       no-error.

            if codiglos.log-1 
            then assign lg-tem-glosa-fracionamento  = yes.
            else do:
                if codiglos.cd-classe-erro  = 10 
                or codiglos.cd-classe-erro  = 23
                or codiglos.cd-classe-erro  = 24
                or codiglos.cd-classe-erro  = 44
                or codiglos.cd-classe-erro  = 45
                or codiglos.cd-classe-erro  = 126
                then do:
                    if moviproc.qti-quant-proced-dispon = 0
                    then assign lg-tem-outras-glosas        = yes
                                lg-tem-glosa-quantitativo   = no.
                    else assign lg-tem-glosa-quantitativo   = yes.
                end.
                else assign lg-tem-outras-glosas    = yes.
            end.
        end.          
    end.
   
    if  mov-insu.vl-cobrado > 0
    and mov-insu.vl-cobrado < mov-insu.vl-insumo
    then assign vl-movto    = mov-insu.vl-cobrado.
    else assign vl-movto    = mov-insu.vl-insumo.
       
    if  mov-insu.cd-tipo-pagamento  = 1 /*Desconsiderar Pagamento */
    then do:
        if lg-tem-outras-glosas 
        then assign vl-glosado-par = vl-movto.
        else do:
            if  lg-tem-glosa-fracionamento 
            and lg-tem-glosa-quantitativo
            then do:
                if mov-insu.val-quant-insumo-dispon - mov-insu.dec-23 <= 0   
                then assign vl-glosado-par  = vl-movto
                            in-qt-glosado   = mov-insu.qt-insumo.
                else assign vl-glosado-par  = ((mov-insu.qt-insumo - (mov-insu.val-quant-insumo-dispon - mov-insu.dec-23)) * vl-movto / mov-insu.qt-insumo)
                            in-qt-glosado   = mov-insu.qt-insumo - (mov-insu.val-quant-insumo-dispon - mov-insu.dec-23).
            end.
            else do:
                if lg-tem-glosa-quantitativo 
                then assign vl-glosado-par = ((mov-insu.qt-insumo - mov-insu.val-quant-insumo-dispon) * vl-movto / mov-insu.qt-insumo)
                            in-qt-glosado   = mov-insu.qt-insumo - mov-insu.val-quant-insumo-dispon. 

                if lg-tem-glosa-fracionamento 
                then do:
                    if mov-insu.dec-23 >= mov-insu.qt-insumo
                    then assign vl-glosado-par  = vl-movto
                                 in-qt-glosado  = mov-insu.qt-insumo.
                    else assign vl-glosado-par  = (mov-insu.dec-23 * vl-movto / mov-insu.qt-insumo)
                                in-qt-glosado   = mov-insu.dec-23.
                end.
            end.
        end.
    end.
    else do: /* 0 - Pagamento conforme contrato */
        if lg-tem-glosa-fracionamento 
        then do:
            /* Desconto do pagamento a quantidade glosada */
            if mov-insu.dec-23 > 0
            then do:
                if mov-insu.dec-23 >= mov-insu.qt-insumo
                then assign vl-glosado-par  = vl-movto
                            in-qt-glosado   = mov-insu.qt-insumo.
                else assign vl-glosado-par  = (mov-insu.dec-23 * vl-movto / mov-insu.qt-insumo)
                            in-qt-glosado   = mov-insu.dec-23.
            end.
            else assign vl-glosado-par = 0.   
        end.
        else assign vl-glosado-par = 0.   
    end.

    assign in-qt-glosa      = in-qt-glosado
           dc-valor-glosa   = vl-glosado-par.
           
end procedure.

procedure BuscaValorGlosadoProcedimento:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define output   parameter dc-valor-glosa            as   decimal    no-undo.
    define output   parameter in-qt-glosa               as   integer    no-undo.
    
    define variable lg-tem-glosa-quantitativo           as   logical    no-undo.
    define variable lg-tem-outras-glosas                as   logical    no-undo.
    define variable lg-tem-glosa-fracionamento          as   logical    no-undo.
    define variable in-qt-glosado                       as   integer    no-undo.   
    define variable vl-glosado-par                      as   decimal    no-undo.    
    define variable vl-movto                            as   decimal    no-undo.  
    
    if  moviproc.cd-cod-glo   <> 0
    then do:
         
        for each movrcglo no-lock
       use-index movrcgl1
           where movrcglo.cd-unidade            = moviproc.cd-unidade
             and movrcglo.cd-unidade-prestadora = moviproc.cd-unidade-prestadora
             and movrcglo.cd-transacao          = moviproc.cd-transacao
             and movrcglo.nr-serie-doc-original = moviproc.nr-serie-doc-original
             and movrcglo.nr-doc-original       = moviproc.nr-doc-original
             and movrcglo.nr-doc-sistema        = moviproc.nr-doc-sistema
             and movrcglo.nr-processo           = moviproc.nr-processo
             and movrcglo.nr-seq-digitacao      = moviproc.nr-seq-digitacao:

            find first codiglos no-lock  
             use-index codiglo1
                 where codiglos.cd-cod-glo   = movrcglo.cd-cod-glo
                   and codiglos.dt-limite   >= moviproc.dt-realizacao
                       no-error.
 
            if codiglos.log-1 
            then do:
                assign lg-tem-glosa-fracionamento = yes.
            end.
            else do:
                if codiglos.cd-classe-erro  = 10 
                or codiglos.cd-classe-erro  = 23
                or codiglos.cd-classe-erro  = 24
                or codiglos.cd-classe-erro  = 44
                or codiglos.cd-classe-erro  = 45
                or codiglos.cd-classe-erro  = 126
                then do:
                    if moviproc.qti-quant-proced-dispon = 0
                    then assign lg-tem-outras-glosas      = yes
                                lg-tem-glosa-quantitativo = no.
                    else assign lg-tem-glosa-quantitativo = yes.
                end.
                else assign lg-tem-outras-glosas      = yes.
            end.
        end.
    end.   
    
    if  moviproc.vl-cobrado > 0
    and moviproc.vl-cobrado < (moviproc.vl-principal + moviproc.vl-auxiliar)
    then assign vl-movto    = moviproc.vl-cobrado.
    else assign vl-movto    = (moviproc.vl-principal + moviproc.vl-auxiliar).
    
    if  moviproc.cd-tipo-pagamento  = 1 /*Desconsiderar Pagamento */
    then do:
        if lg-tem-outras-glosas 
        then assign vl-glosado-par = vl-movto.
        else do:
            if  lg-tem-glosa-fracionamento 
            and lg-tem-glosa-quantitativo
            then do:
                if moviproc.qti-quant-proced-dispon - moviproc.dec-23 <= 0
                then assign vl-glosado-par  = vl-movto
                            in-qt-glosado   = moviproc.qt-procedimentos.
                else assign vl-glosado-par  = ((moviproc.qt-procedimentos - (moviproc.qti-quant-proced-dispon - moviproc.dec-23)) * vl-movto / moviproc.qt-procedimentos)
                            in-qt-glosado   = moviproc.qt-procedimentos - (moviproc.qti-quant-proced-dispon - moviproc.dec-23).
            end.
            else do:
                if lg-tem-glosa-quantitativo 
                then assign vl-glosado-par  = ((moviproc.qt-procedimentos - moviproc.qti-quant-proced-dispon) * vl-movto / moviproc.qt-procedimentos)
                            in-qt-glosado   = moviproc.qt-procedimentos - moviproc.qti-quant-proced-dispon.

                if lg-tem-glosa-fracionamento 
                then do:
                    if moviproc.dec-23 >= moviproc.qt-procedimentos
                    then assign vl-glosado-par  = vl-movto
                                in-qt-glosado   = moviproc.qt-procedimentos.
                    else assign vl-glosado-par  = (moviproc.dec-23 * vl-movto / moviproc.qt-procedimentos)
                                in-qt-glosado   = moviproc.dec-23.
                end.
            end.
        end.
    end.
    else do: /* 0 - Pagamento conforme contrato */
        if  lg-tem-glosa-fracionamento 
        then do:
            /* Desconto do pagamento a quantidade glosada */
            if moviproc.dec-23  > 0
            then do:
                if moviproc.dec-23 >= moviproc.qt-procedimentos
                then assign vl-glosado-par  = vl-movto
                            in-qt-glosado   = moviproc.qt-procedimentos.
                else assign vl-glosado-par  = (moviproc.dec-23 * vl-movto / moviproc.qt-procedimentos)
                            in-qt-glosado   = moviproc.dec-23.
            end.
            else assign vl-glosado-par = 0.   
        end.
        else assign vl-glosado-par = 0.   
    end.
    
    assign in-qt-glosa      = in-qt-glosado
           dc-valor-glosa   = vl-glosado-par.
end procedure.

procedure Executa:
    define input  parameter table for temp-parametro-entrada.
    define input  parameter table for temp-parametro-periodo.

    define variable dt-alterado-desde           as   date       init today  no-undo.
    define variable ch-holder                   as   character              no-undo.
    define variable ch-modo                     as   character              no-undo.
    define variable dt-base                     as   date                   no-undo.
    define variable in-ano                      as   integer                no-undo.
    define variable in-mes                      as   integer                no-undo.

        for each temp-parametro-periodo:
            run Processa (input  temp-parametro-periodo.in-mes, 
                          input  temp-parametro-periodo.in-ano).
        end.
end procedure.    

procedure Processa:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input        parameter in-mes                as   integer    no-undo.
    define input        parameter in-ano                as   integer    no-undo.
    
    define variable in-conta                    as   integer        no-undo.
    
    find first paramecp no-lock.
            
    for each fatura no-lock
   use-index fatura13 
       where fatura.aa-referencia               = in-ano
         and fatura.mm-referencia               = in-mes
         and fatura.cd-modalidade              <> ? 
         and (   fatura.in-tipo-fatura          = 0         /* PP, participacao ou custo */
              or fatura.in-tipo-fatura          = 1         /* fatura outras unidades */
              or fatura.in-tipo-fatura          = 5         /* intercambio - fatura contra unidade */
              or fatura.in-tipo-fatura          = 6),       /* intercambio - fatura contra benef */
        each notaserv no-lock
   use-index notaserv3
       where notaserv.cd-contratante            = fatura.cd-contratante
         and notaserv.nr-fatura                 = fatura.nr-fatura,
        each fateveco no-lock
   use-index fatevec3        
       where fateveco.cd-modalidade             = notaserv.cd-modalidade
         and fateveco.nr-ter-adesao             = notaserv.nr-ter-adesao
         and fateveco.aa-referencia             = notaserv.aa-referencia
         and fateveco.mm-referencia             = notaserv.mm-referencia
         and fateveco.nr-sequencia              = notaserv.nr-sequencia
         and fateveco.cd-contratante            = notaserv.cd-contratante
         and fateveco.cd-contratante-origem     = notaserv.cd-contratante-origem,
       first contrat no-lock
   use-index contra12
       where contrat.cd-contratante             = fatura.cd-contratante:                       
     
        if  fatura.in-tipo-fatura   = 1
        and fatura.log-16
        then next.

        /* Considera apenas se a nota de serviáo for de custo */
        if fatura.in-tipo-fatura    = 0
        then do:
            if  notaserv.in-tipo-nota  <> 1 /* Custo operacional */
            and notaserv.in-tipo-nota  <> 8
            then next.
        end.

        log-manager:write-message (substitute ('lendo fatura &1/&2, data emissao: &3', 
                                               fatura.cd-contratante, 
                                               fatura.nr-fatura, 
                                               fatura.dt-emissao), 
                                   'DEBUG').
        
        if available propost then release propost.
        if available usuario then release usuario.
        
        if fateveco.cd-tipo-cob = 0 /** PROCEDIMENTO **/        
        then do:
            run AnalisaProcedimento (input-output in-conta).            
        end.  
        else do:
            run AnalisaInsumo (input-output in-conta).
        end.    
        
        if in-conta = 500
        then do:
            EnviarDados (dataset XML_DOCUMENTOS:handle).
            dataset XML_DOCUMENTOS:empty-dataset ().
            assign in-conta  = 0.
        end.
    end.    
    EnviarDados (dataset XML_DOCUMENTOS:handle).
end procedure.


/* ************************  Function Implementations ***************** */

function ObtemOrigem returns character 
    (in-unidade-carteira    as   integer,
     in-modalidade          as   integer,
     in-termo-adesao        as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

    if in-unidade-carteira <> paramecp.cd-unimed then return ORIGEM_INTERCAMBIO.

    find first propost no-lock
         where propost.cd-modalidade    = in-modalidade
           and propost.nr-ter-adesao    = in-termo-adesao.
           
    if propost.cd-forma-pagto   = 1
    then return ORIGEM_PREPAGAMENTO.
    
    return ORIGEM_CUSTOOPERACIONAL.              
end function.

