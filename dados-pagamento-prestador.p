
/*------------------------------------------------------------------------
    File        : dados-contratos.p
    Purpose     : 

    Syntax      :  
 
    Description : 

    Author(s)   : 
    Created     : Tue Dec 05 10:29:15 BRST 2017
    Notes       :
  ----------------------------------------------------------------------*/
 
/* ***************************  Definitions  ************************** */
routine-level on error undo, throw.

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
  

define temp-table XML_PAGAMENTO no-undo
    namespace-uri "http://wwww.thealth.com.br" 
    field CHAVE_SISTEMA as character 
    field CODIGO as character 
    field DATA_GERACAO as date 
    field DATA_VENCIMENTO as date 
    field ANO_PRODUCAO as integer 
    field MES_PRODUCAO as integer 
    field VALOR as decimal     
    field CHAVE_SISTEMA_PRESTADOR as character .

define temp-table XML_EVENTO no-undo
    namespace-uri "http://wwww.thealth.com.br" 
    field CHAVE_SISTEMA_EVENTO as character 
    field QUANTIDADE as integer 
    field VALOR as decimal 
    field XML_PAGAMENTO_id as recid 
        xml-node-type "HIDDEN" .

define temp-table XML_DADOS_EXTRA no-undo
    namespace-uri "http://wwww.thealth.com.br" 
    field CAMPO as character 
    field VALOR as character 
    field XML_EVENTO_id as recid 
        xml-node-type "HIDDEN" 
    field XML_MOVIMENTO_id as recid 
        xml-node-type "HIDDEN" 
    field XML_PAGAMENTO_id as recid 
        xml-node-type "HIDDEN" .

define temp-table XML_MOVIMENTO no-undo
    namespace-uri "http://wwww.thealth.com.br" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_PROC_INSU as character 
    field TIPO_MOVIMENTO as character 
    field QUANTIDADE as integer 
    field VALOR as decimal 
    field CHAVE_SISTEMA_ESPECIALIDADE as character 
    field XML_PAGAMENTO_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_PAGAMENTOS namespace-uri "http://wwww.thealth.com.br" 
    for XML_PAGAMENTO, XML_EVENTO, XML_DADOS_EXTRA, XML_MOVIMENTO
    parent-id-relation RELATION1 for XML_EVENTO, XML_DADOS_EXTRA
        parent-id-field XML_EVENTO_id
    parent-id-relation RELATION2 for XML_PAGAMENTO, XML_EVENTO
        parent-id-field XML_PAGAMENTO_id
    parent-id-relation RELATION3 for XML_MOVIMENTO, XML_DADOS_EXTRA
        parent-id-field XML_MOVIMENTO_id
    parent-id-relation RELATION4 for XML_PAGAMENTO, XML_MOVIMENTO
        parent-id-field XML_PAGAMENTO_id
    parent-id-relation RELATION5 for XML_PAGAMENTO, XML_DADOS_EXTRA
        parent-id-field XML_PAGAMENTO_id.
 

/*------------------------------------------------------------------------
    File        : dates.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Oct 13 14:54:32 BRT 2015
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
define variable DATA_FORMATO_YYYY_MM_DD_COM_SEPARADOR   as   character          no-undo initial "YYYY-MM-DD".
define variable DATA_FORMATO_DD_MM_YYYY_COM_SEPARADOR   as   character          no-undo initial "DD-MM-YYYY".
define variable DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR   as   character          no-undo initial "DDMMYYYY".

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */

function UltimoDiaMesAtual returns date 
        (  ) forward.

function DiasNoMes returns integer 
        (in-ano as integer,
         in-mes as integer) forward.

function PrimeiroDiaMesAtual returns date 
        (  ) forward.


/* ***************************  Main Block  *************************** */




/* ************************  Function Implementations ***************** */
function DataEstaSobreposta returns logical
    (input dt-1-initial         as date,
     input dt-1-final           as date,
     input dt-2-initial         as date,
     input dt-2-final           as date):

    if (    dt-2-initial   >= dt-1-initial
        and dt-2-initial   <= dt-1-final)
    or (    dt-2-final     >= dt-1-initial
        and dt-2-final     <= dt-1-final)
    or (    dt-1-initial   >= dt-2-initial
        and dt-1-initial   <= dt-2-final)
    or (    dt-1-final     >= dt-2-initial
        and dt-1-final     <= dt-2-final)
    then return yes.
    else return no.
end function.



function ConverterParaData returns date
    (input ch-date-string       as   character,
     input ch-formato           as   character):

    define variable dt-value    as   date       no-undo.

    case ch-formato:
        when DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR
        then do:
            dt-value    = date (integer (substring (ch-date-string, 3, 2)),
                                integer (substring (ch-date-string, 1, 2)),
                                integer (substring (ch-date-string, 5, 4)))
                                no-error.
            if error-status:error then return ?.                                
        end.
        when DATA_FORMATO_YYYY_MM_DD_COM_SEPARADOR
        then do:
            dt-value    = date (integer (substring (ch-date-string, 6, 2)),
                                integer (substring (ch-date-string, 9, 2)),
                                integer (substring (ch-date-string, 1, 4)))
                                no-error.
                             
            if error-status:error then return ?.                                        
        end.
        when DATA_FORMATO_DD_MM_YYYY_COM_SEPARADOR
        then do:
            dt-value    = ConverterParaData (replace (replace (ch-date-string, "/", ""), "-", ""), DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR).
            if error-status:error then return ?.
        end.
        
        otherwise do:
        end.
    end.
    return dt-value.                                
         
end.     


function UltimoDiaMes returns date    
    (in-ano         as   integer,
     in-mes         as   integer):

    define variable dt-ultimo-dia-mes       as   date       no-undo.
         
    assign dt-ultimo-dia-mes    = date (in-mes, 1, in-ano)
           dt-ultimo-dia-mes    = add-interval (dt-ultimo-dia-mes, 1, "month")
           dt-ultimo-dia-mes    = dt-ultimo-dia-mes - 1.
           
    return dt-ultimo-dia-mes.           
         
end function.         

function DiasNoMes returns integer 
        (in-ano as integer,
         in-mes as integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        

    define variable dt-ini      as   date   no-undo.
    define variable dt-fim      as   date   no-undo.
    
    assign dt-ini   = date (in-mes, 1, in-ano)
           dt-fim   = UltimoDiaMes (in-ano, in-mes).
           
    return interval (dt-fim, dt-ini, "days") + 1.           
end function.

function PrimeiroDiaMesAtual returns date 
        (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    return date (month (today), 1, year (today)).


                
end function.
             


function FormatarData returns character
      (input ch-value           as date,
       input ch-format          as character, 
       input ch-separator       as character, 
       input lg-include-time    as logical,
       input ch-time-separator  as character): 
       
    define variable va-format                 as character.
    define variable ch-original-date-format   as character format "x(3)". 
    define variable va-return                 as character.

    ch-original-date-format = session:date-format.

    case ch-format:
        when "YYYYMMDD" 
        then do:
            session:date-format = "YMD".
            va-format = "9999" + "-" + "99" + "-" + "99".
        end.
        when "MMDDYYYY" 
        then do:
            session:date-format = "MDY".
            va-format = "99" + "-" + "99" + "-" + "9999".
        end.  
        when "DDMMYYYY" 
        then do:
            session:date-format = "DMY".
            va-format = "99" + "-" + "99" + "-" + "9999".
        end.
  
        when "YYMMDD" 
        then do:
            session:date-format = "YMD".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
  
        when "MMDDYY" 
        then do:
            session:date-format = "MDY".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
  
        when "DDMMYY" 
        then do:
            session:date-format = "DMY".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
     
        when "ISO" 
        then do:
            va-return = iso-date (ch-value).
            va-return = replace (va-return,"-",ch-separator).
            va-return = replace (replace (va-return,":",ch-time-separator),".",ch-time-separator).  /* 2009-02-27T10:51:47.261-05:00 */
        end.
 
        otherwise
            va-format = "99" + "-" + "99" + "-" + "99".
     
    end case.   
  
    if ch-format <> "ISO" 
    then do:
        if lg-include-time 
        then va-return = replace(replace(replace(string(ch-value,va-format + " HH:MM:SS.SSS"),":",ch-time-separator),".",ch-time-separator)," ",ch-time-separator).
        else va-return = string(ch-value, va-format).
        
        va-return = replace(va-return,"-",ch-separator).
   end.
  
  
    session:date-format = ch-original-date-format. 
    return va-return.

end function.   

function UltimoDiaMesAtual returns date 
        (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    return UltimoDiaMes(year(today), month(today)).

                
end function.
 
/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */



/* ***************************  Main Block  *************************** */
define variable MOVIMENTO_PROCEDIMENTO          as   character      init 'PROCEDIMENTO' no-undo.
define variable MOVIMENTO_INSUMO                as   character      init 'INSUMO'       no-undo.
 

/* **********************  Internal Procedures  *********************** */



procedure BuscaEventos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    for each movipres no-lock
   use-index movipr10
       where movipres.cd-unidade            = titupres.cd-unidade
         and movipres.cd-unidade-prestador  = titupres.cd-unidade-prestador
         and movipres.cd-tipo-medicina      = titupres.cd-tipo-medicina
         and movipres.cd-prestador          = titupres.cd-prestador
         and movipres.referencia            = titupres.referencia
         and movipres.nr-nota-parcela       = string (titupres.cod-docto-ap + string(titupres.parcela,"99"))
         and movipres.lg-processado         = yes,
       first evenfatu no-lock               
   use-index evenfat1
       where evenfatu.cd-evento             = movipres.cd-evento
         and evenfatu.in-classe-evento      = "PP":
             
        create XML_EVENTO.
        assign XML_EVENTO.CHAVE_SISTEMA_EVENTO  = RegistroPrimary (buffer evenfatu:handle)
               XML_EVENTO.XML_PAGAMENTO_id      = recid (XML_PAGAMENTO)
               XML_EVENTO.QUANTIDADE            = movipres.qt-movto
               XML_EVENTO.VALOR                 = movipres.vl-movto.                                                
               
    end.
   

end procedure.

procedure BuscaInsumos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    for each movimen-insumo-nota no-lock         
   use-index mvmnnsmn-03
       where movimen-insumo-nota.cd-unidade             = titupres.cd-unidade
         and movimen-insumo-nota.cd-unidade-pagamento   = titupres.cd-unidade-prestador
         and movimen-insumo-nota.cd-prestador-pagamento = titupres.cd-prestador
         and movimen-insumo-nota.parcela-pp             = titupres.parcela
         and movimen-insumo-nota.cd-tipo-medicina       = titupres.cd-tipo-medicina
         and movimen-insumo-nota.cod-esp-pp             = titupres.cod-esp
         and movimen-insumo-nota.cod-docto-pagto-ap     = titupres.cod-docto-ap:             
                     
        log-manager:write-message (substitute ('lendo movimen-insumo-nota &1', RegistroPrimary(buffer movimen-insumo-nota:handle)),'DEBUG').
                     
        for each mov-insu no-lock
       use-index mov-ins1
           where mov-insu.cd-unidade            = movimen-insumo-nota.cd-unidade
             and mov-insu.cd-unidade-prestadora = movimen-insumo-nota.cd-unidade-prestadora
             and mov-insu.cd-transacao          = movimen-insumo-nota.cd-transacao
             and mov-insu.nr-serie-doc-original = movimen-insumo-nota.nr-serie-doc-original
             and mov-insu.nr-doc-original       = movimen-insumo-nota.nr-doc-original
             and mov-insu.nr-doc-sistema        = movimen-insumo-nota.nr-doc-sistema
             and mov-insu.nr-processo           = movimen-insumo-nota.nr-processo
             and mov-insu.nr-seq-digitacao      = movimen-insumo-nota.nr-seq-digitacao,
           first insumos no-lock
       use-index insumo1
           where insumos.cd-tipo-insumo         = mov-insu.cd-tipo-insumo 
             and insumos.cd-insumo              = mov-insu.cd-insumo:

            log-manager:write-message (substitute ('lendo mov-insu &1', RegistroPrimary (buffer mov-insu:handle) ),'DEBUG').

            find first previesp no-lock
                 where previesp.cd-unidade          = mov-insu.cd-unidade-prestador
                   and previesp.cd-prestador        = mov-insu.cd-prestador-pagamento
                   and previesp.cd-vinculo          = mov-insu.cd-tipo-vinculo
                   and previesp.dt-inicio-validade <= mov-insu.dt-realizacao 
                   and previesp.dt-fim-validade    >= mov-insu.dt-realizacao.
           
            find first esp-med no-lock 
                 where esp-med.cd-especialid    = previesp.cd-especialid.
    
            log-manager:write-message (substitute ('criando movimento'),'DEBUG').                       
                       
            create XML_MOVIMENTO.
            assign XML_MOVIMENTO.CHAVE_SISTEMA                  = RegistroPrimary(buffer mov-insu:handle)
                   XML_MOVIMENTO.XML_PAGAMENTO_id               = recid (XML_PAGAMENTO)
                   XML_MOVIMENTO.CHAVE_SISTEMA_PROC_INSU        = RegistroPrimary (buffer insumos:handle)
                   XML_MOVIMENTO.TIPO_MOVIMENTO                 = MOVIMENTO_INSUMO
                   XML_MOVIMENTO.QUANTIDADE                     = mov-insu.qt-cobrado // BUG buscar valor correto

                   XML_MOVIMENTO.VALOR                          = mov-insu.vl-real-pago
                   XML_MOVIMENTO.CHAVE_SISTEMA_ESPECIALIDADE    = RegistroPrimary (buffer esp-med:handle).
                                                                                 
                         
        end.     
    end.                              


end procedure.

procedure BuscaProcedimentos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    for each movimen-proced-nota no-lock
   use-index mvmnprcc-03
       where movimen-proced-nota.cd-unidade             = titupres.cd-unidade
         and movimen-proced-nota.cd-unidade-pagamento   = titupres.cd-unidade-prestador
         and movimen-proced-nota.cd-prestador-pagamento = titupres.cd-prestador
         and movimen-proced-nota.parcela-pp             = titupres.parcela
         and movimen-proced-nota.cd-tipo-medicina       = titupres.cd-tipo-medicina
         and movimen-proced-nota.cod-esp-pp             = titupres.cod-esp
         and movimen-proced-nota.cod-docto-pagto-ap     = titupres.cod-docto-ap:

        log-manager:write-message (substitute ('lendo movimen-proced-nota &1', RegistroPrimary(buffer movimen-proced-nota:handle)),'DEBUG').
        
        for each moviproc
       use-index movipro1
           where moviproc.cd-unidade            = movimen-proced-nota.cd-unidade
             and moviproc.cd-unidade-prestadora = movimen-proced-nota.cd-unidade-prestadora
             and moviproc.cd-transacao          = movimen-proced-nota.cd-transacao
             and moviproc.nr-serie-doc-original = movimen-proced-nota.nr-serie-doc-original
             and moviproc.nr-doc-original       = movimen-proced-nota.nr-doc-original
             and moviproc.nr-doc-sistema        = movimen-proced-nota.nr-doc-sistema
             and moviproc.nr-processo           = movimen-proced-nota.nr-processo
             and moviproc.nr-seq-digitacao      = movimen-proced-nota.nr-seq-digitacao,
           first ambproce no-lock
       use-index ambproc1
           where ambproce.cd-esp-amb            = moviproc.cd-esp-amb 
             and ambproce.cd-grupo-proc-amb     = moviproc.cd-grupo-proc-amb
             and ambproce.cd-procedimento       = moviproc.cd-procedimento
             and ambproce.dv-procedimento       = moviproc.dv-procedimento:
        
            log-manager:write-message (substitute ('lendo moviproc &1', RegistroPrimary (buffer moviproc:handle) ),'DEBUG').
        
            find first previesp no-lock
                 where previesp.cd-unidade          = moviproc.cd-unidade-prestador
                   and previesp.cd-prestador        = moviproc.cd-prestador-pagamento
                   and previesp.cd-vinculo          = moviproc.cd-tipo-vinculo
                   and previesp.dt-inicio-validade <= moviproc.dt-realizacao 
                   and previesp.dt-fim-validade    >= moviproc.dt-realizacao.
                   
            find first esp-med no-lock 
                 where esp-med.cd-especialid    = previesp.cd-especialid 
                       no-error.                                                                       
                                      
            log-manager:write-message (substitute ('criando movimento'),'DEBUG').
                                                  
            create XML_MOVIMENTO.
            assign XML_MOVIMENTO.CHAVE_SISTEMA                  = RegistroPrimary(buffer moviproc:handle)
                   XML_MOVIMENTO.XML_PAGAMENTO_id               = recid (XML_PAGAMENTO)
                   XML_MOVIMENTO.CHAVE_SISTEMA_PROC_INSU        = RegistroPrimary (buffer ambproce:handle)
                   XML_MOVIMENTO.TIPO_MOVIMENTO                 = MOVIMENTO_PROCEDIMENTO
                   XML_MOVIMENTO.QUANTIDADE                     = moviproc.qt-cobrado // BUG buscar valor correto

                   XML_MOVIMENTO.VALOR                          = movimen-proced-nota.vl-real-pago
                   XML_MOVIMENTO.CHAVE_SISTEMA_ESPECIALIDADE    = RegistroPrimary (buffer esp-med:handle).
                 
        end.
    end.


end procedure.

procedure Executa: 
    define input  parameter table for temp-parametro-entrada.
    define input  parameter table for temp-parametro-periodo.

    define variable dt-inicial                  as   date       no-undo.
    define variable dt-final                    as   date       no-undo.

    find first temp-parametro-entrada.
    
    find first paramecp no-lock.
    for each temp-parametro-periodo:
        
        assign dt-inicial   = date (temp-parametro-periodo.in-mes, 1, temp-parametro-periodo.in-ano)
               dt-final     = UltimoDiaMes (temp-parametro-periodo.in-ano, temp-parametro-periodo.in-mes).

        for each titupres no-lock //Corrigir indice

       use-index titupr10
           where titupres.cd-unidade            = paramecp.cd-unimed
             and titupres.cd-unidade-prestador  = paramecp.cd-unimed
             and titupres.cd-prestador          > 0
             and titupres.dt-producao          >= dt-inicial
             and titupres.dt-producao          <= dt-final,
           first preserv no-lock
       use-index preserv1
           where preserv.cd-unidade             = titupres.cd-unidade-prestador
             and preserv.cd-prestador           = titupres.cd-prestador:
                 
            if titupres.in-tipo-titulo <> "NO"
            then next.
                
            create XML_PAGAMENTO.
            assign XML_PAGAMENTO.CHAVE_SISTEMA              = RegistroPrimary (buffer titupres:handle)
                   XML_PAGAMENTO.CHAVE_SISTEMA_PRESTADOR    = RegistroPrimary (buffer preserv:handle)
                   XML_PAGAMENTO.DATA_GERACAO               = titupres.dt-atualizacao
                   XML_PAGAMENTO.DATA_VENCIMENTO            = titupres.dt-vencimento
                   XML_PAGAMENTO.VALOR                      = titupres.vl-saldo
                   XML_PAGAMENTO.ANO_PRODUCAO               = year (titupres.dt-producao)
                   XML_PAGAMENTO.MES_PRODUCAO               = month (titupres.dt-producao)
                   XML_PAGAMENTO.CODIGO                     = XML_PAGAMENTO.CHAVE_SISTEMA.                   
         
            run BuscaEventos.
            run BuscaProcedimentos.
            run BuscaInsumos.
            
            EnviarDados (dataset XML_PAGAMENTOS:handle).
            dataset XML_PAGAMENTOS:empty-dataset ().
        end.                                                   
    end. 
end procedure.
 
/* ************************  Function Implementations ***************** */

