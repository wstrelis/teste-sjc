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
/*------------------------------------------------------------------------
    File        : simular-faturamento.i 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Oct 05 15:55:56 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-faturamento-contrato no-undo
    field in-modalidade                     as   integer
    field in-termo                          as   integer
    field in-ano                            as   integer
    field in-mes                            as   integer
    field dc-valor-total                    as   decimal.
    
    
define temp-table temp-faturamento-beneficiario   
                                            no-undo    
    field in-modalidade                     as   integer
    field in-termo                          as   integer
    field in-usuario                        as   integer
    field in-ano                            as   integer
    field in-mes                            as   integer
    field in-evento                         as   integer
    field ch-classe-evento                  as   character
    field dc-valor                          as   decimal
    field ch-tipo-movimento                 as   character.
    

/*------------------------------------------------------------------------
    File        : utilidades.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Oct 06 09:35:13 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function BuscaValorFaturamentoPrepagamentoContrato returns decimal 
    (in-modalidade      as   integer,
     in-termo           as   integer,
     in-ano             as   integer,
     in-mes             as   integer  ) forward.

function EhEventoMensalidade returns logical 
    (ch-classe-evento               as   character) forward.

function IdadeBeneficiario returns integer 
    (dt-nascimento      as   date,
     dt-calculo         as   date) forward.

function ValorTotalMensalidade returns decimal 
    (in-modalidade          as   integer,
     in-termo               as   integer,
     in-usuario             as   integer) forward.

/* ***************************  Main Block  *************************** */


/* ************************  Function Implementations ***************** */

function BuscaValorFaturamentoPrepagamentoContrato returns decimal 
    (in-modalidade      as   integer,
     in-termo           as   integer,
     in-ano             as   integer,
     in-mes             as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable dc-valor                    as   decimal    no-undo.
    
    define buffer buf-notaserv                  for  notaserv.
    
    find first buf-notaserv no-lock
     use-index notaserv7    
         where buf-notaserv.cd-modalidade       = in-modalidade
           and buf-notaserv.nr-ter-adesao       = in-termo
           and buf-notaserv.aa-referencia       = in-ano
           and buf-notaserv.mm-referencia       = in-mes
           and (   buf-notaserv.in-tipo-nota    = 0
                or buf-notaserv.in-tipo-nota    = 5)
               no-error.
              
    if available buf-notaserv
    then assign dc-valor    = buf-notaserv.vl-total.

    return dc-valor.
        
end function.

function EhEventoMensalidade returns logical 
    (ch-classe-evento               as   character ):

    if ch-classe-evento    = "A"
    or ch-classe-evento    = "K"
    or ch-classe-evento    = "L"
    or ch-classe-evento    = "N"
    or ch-classe-evento    = "O"
    or ch-classe-evento    = "P"
    or ch-classe-evento    = "Q"
    or ch-classe-evento    = "W"
    or ch-classe-evento    = "4"
    then do:
        return yes.
    end.                                     
    return no.       
end function.

function IdadeBeneficiario returns integer 
    (dt-nascimento      as   date,
     dt-calculo         as   date  ):

    define variable lg-erro                                     as   logical    no-undo.
    define variable in-idade-beneficiario                       as   integer    no-undo.
    
    run rtp/rtidade.p (input  dt-nascimento,
                       input  dt-calculo,
                       output in-idade-beneficiario,
                       output lg-erro).
                     
    if lg-erro then return ?.
    
    return in-idade-beneficiario.                         
        
end function.

function ValorTotalMensalidade returns decimal 
    (in-modalidade          as   integer,
     in-termo               as   integer,
     in-usuario             as   integer):
             
    define buffer buf-benef         for  temp-faturamento-beneficiario.    
    define variable dc-valor        as   decimal    no-undo.
    
    for each buf-benef
       where buf-benef.in-modalidade    = in-modalidade
         and buf-benef.in-termo         = in-termo
         and buf-benef.in-usuario       = in-usuario:
              
             
        find first evenfatu no-lock
             where evenfatu.in-entidade     = 'FT'
               and evenfatu.cd-evento       = buf-benef.in-evento.
             
        if EhEventoMensalidade (buf-benef.ch-classe-evento)
        then do:
            if buf-benef.ch-tipo-movimento  = 'CREDITO'
            then do:
                assign dc-valor = dc-valor + buf-benef.dc-valor.
            end.
            else do:
                assign dc-valor = dc-valor - buf-benef.dc-valor.
            end.   
        end.        
    end.
    return dc-valor.
end function.

procedure BuscaValorUltimoFaturamento:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-modalidade       as   integer    no-undo.
    define input  parameter in-termo            as   integer    no-undo.
    define output parameter dc-valor            as   decimal    no-undo.
    
    define buffer buf-notaserv                  for  notaserv.
    
    find last buf-notaserv no-lock
        where buf-notaserv.cd-modalidade        = in-modalidade
          and buf-notaserv.nr-ter-adesao        = in-termo
          and buf-notaserv.aa-referencia       <> 0
          and buf-notaserv.mm-referencia       <> 0
          and (   buf-notaserv.in-tipo-nota     = 0
               or buf-notaserv.in-tipo-nota     = 5)
              no-error.
              
    if available buf-notaserv
    then assign dc-valor    = buf-notaserv.vl-total.
end procedure.
    
 

/*------------------------------------------------------------------------
    File        : data-vencimento.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Dec 19 09:05:33 BRST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function CalculaDataVencimentoProposta returns datetime 
    (in-modalidade              as   integer,
     in-termo-adesao            as   integer,
     dt-emissao                 as   date,
     in-mes-referencia          as   integer,
     in-ano-referencia          as   integer) forward.


/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function CalculaDataVencimentoProposta returns datetime 
    (in-modalidade              as   integer,
     in-termo-adesao            as   integer,
     dt-emissao                 as   date,
     in-mes-referencia          as   integer,
     in-ano-referencia          as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define buffer buf-prop                  for  propost.
    define variable ep-codigo-aux           like propost.ep-codigo.
    define variable cod-estabel-aux         like propost.cod-estabel.
    define variable cd-tipo-vencimento-aux  like propost.cd-tipo-vencimento.
    define variable dd-vencimento-aux       like propost.dd-vencimento.
    define variable dt-vencimento-aux       as   date.
    define variable ds-mens-aux             as   character.
    define variable lg-erro-aux             as   logical.
    
    find first buf-prop no-lock
         where buf-prop.cd-modalidade   = in-modalidade
           and buf-prop.nr-ter-adesao   = in-termo-adesao.
           
     assign ep-codigo-aux            = propost.ep-codigo
            cod-estabel-aux          = propost.cod-estabel
            cd-tipo-vencimento-aux   = propost.cd-tipo-vencimento
            dd-vencimento-aux        = propost.dd-vencimento.    

    run rtp/rtdtvenc.p (input ep-codigo-aux,
                        input cod-estabel-aux,
                        input dd-vencimento-aux,
                        input dt-emissao,
                        input-output dt-vencimento-aux,
                        input in-mes-referencia,
                        input in-ano-referencia,
                        input cd-tipo-vencimento-aux,
                        output lg-erro-aux,
                        output ds-mens-aux).
    if (lg-erro-aux)     
    then do:
        return ?.        
    end.
    return dt-vencimento-aux.
        
end function.



   

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
 

define temp-table XML_FATURAMENTO no-undo
    namespace-uri "http://wwww.thealth.com.br/ServiceBilling.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_CONTRATO as character 
    field CHAVE_SISTEMA_RESPONSAVEL_FINANC as character 
        xml-node-name "CHAVE_SISTEMA_RESPONSAVEL_FINANCEIRO" 
    field ANO as integer 
    field MES as integer 
    field TIPO_FATURAMENTO as integer 
    field VALOR_TOTAL as decimal 
    field DATA_GERACAO as date 
    field DATA_VENCIMENTO as date 
    field FATURADO as logical .

define temp-table XML_FATURAMENTO_ITENS no-undo
    namespace-uri "http://wwww.thealth.com.br/ServiceBilling.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_EVENTO as character 
    field VALOR_TOTAL as decimal 
    field CHAVE_SISTEMA_BENEFICIARIO as character 
    field NOME_BENEFICIARIO as character 
    field UNIDADE_CARTEIRA_BENEFICIARIO as integer 
    field CARTEIRA_BENEFICIARIO as character 
    field XML_FATURAMENTO_id as recid 
        xml-node-type "HIDDEN" .

define temp-table XML_EVENTO_EXTRA no-undo
    namespace-uri "http://wwww.thealth.com.br/ServiceBilling.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_EVENTO as character 
    field VALOR_TOTAL as decimal 
    field XML_FATURAMENTO_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_FATURAMENTOS namespace-uri "http://wwww.thealth.com.br/ServiceBilling.xsd" 
    for XML_FATURAMENTO, XML_FATURAMENTO_ITENS, XML_EVENTO_EXTRA
    parent-id-relation RELATION1 for XML_FATURAMENTO, XML_FATURAMENTO_ITENS
        parent-id-field XML_FATURAMENTO_id
    parent-id-relation RELATION2 for XML_FATURAMENTO, XML_EVENTO_EXTRA
        parent-id-field XML_FATURAMENTO_id.
  

function BuscaTipoNotaServico returns character  
    (in-tipo-nota as integer) forward.
 

/* **********************  Internal Procedures  *********************** */

procedure Executa:
    define input  parameter table for temp-parametro-entrada.
    define input  parameter table for temp-parametro-periodo.    
    
    define variable in-ano                      as   integer        no-undo.
    define variable in-mes                      as   integer        no-undo.
    define variable ch-referencia               as   character      no-undo.
    define variable dt-base                     as   date           no-undo.
    
    find first temp-parametro-entrada.
    
    if temp-parametro-entrada.ch-modo   = MODO_EXECUCAO_TOTAL
    then do:
        dt-base = add-interval (today, -12, 'month').
        
        assign in-mes   = month (dt-base)
               in-ano   = year (dt-base).
        
        repeat:
            run ProcessaMesAno (input  in-mes,
                                input  in-ano, 
                                input  ?).
            
            if integer (substitute ('&1&2', string (in-ano, '9999'), string (in-mes, '99'))) > integer (substitute ('&1&2', string (year (today), '9999'), string (month (today), '99')))
            then leave.
 
            in-mes = in-mes + 1.
            if in-mes > 12
            then assign in-mes = 1
                        in-ano = in-ano + 1.                                                                             
        end.       
    end.
    else do:
        if temp-parametro-entrada.lg-parametros-periodos
        then do:
            for each temp-parametro-periodo:
                run ProcessaMesAno (input  temp-parametro-periodo.in-mes,
                                    input  temp-parametro-periodo.in-ano,
                                    input  ?).                
            end.
        end.
        else do:
            run ProcessaMesAno (input  0,
                                input  0,
                                input  temp-parametro-entrada.dt-qt-dias).
        end.
    end.    
end procedure.    

procedure ProcessaMesAno:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-mes                  as   integer        no-undo.
    define input  parameter in-ano                  as   integer        no-undo.
    define input  parameter dt-atualizacao          as   date           no-undo.
        
    define variable ch-referencia               as   character  no-undo.
    
    define variable in-id-fat                   as   integer    no-undo.
    define variable in-id-fat-benef             as   integer    no-undo.
    
    define variable dc-valor-total-benef        as   decimal    no-undo.
    define variable dc-valor-evento             as   decimal    no-undo.
    
    define variable ch-query                    as   character  no-undo.
    define variable hd-query                    as   handle     no-undo.
    
    create query hd-query.
    
    if in-mes = 0
    then do:
        assign ch-query = substitute ("
    for each notaserv no-lock   
       where notaserv.dt-atualizacao   >= &1,
       first propost no-lock
       where propost.cd-modalidade      = notaserv.cd-modalidade
         and propost.nr-ter-adesao      = notaserv.nr-ter-adesao
    break by notaserv.dt-emissao",    dt-atualizacao).
    end.
    else do:
        assign ch-query = substitute ("
    for each notaserv no-lock   
       where notaserv.cd-modalidade     > 0
         and notaserv.nr-ter-adesao     > 0
         and notaserv.aa-referencia     = &1
         and notaserv.mm-referencia     = &2,
       first propost no-lock
       where propost.cd-modalidade      = notaserv.cd-modalidade
         and propost.nr-ter-adesao      = notaserv.nr-ter-adesao
    break by notaserv.dt-emissao",    in-ano,
                                      in-mes).
    end.

    in-id-fat = 0.             
    
    hd-query:set-buffers (buffer notaserv:handle, buffer propost:handle).
    hd-query:query-prepare (ch-query).
    hd-query:query-open().
    
    repeat:
        hd-query:get-next ().
        if hd-query:query-off-end then leave.
        
        find first ter-ade no-lock
             where ter-ade.cd-modalidade    = propost.cd-modalidade
               and ter-ade.nr-ter-adesao    = propost.nr-ter-adesao
                   no-error.
                   
        if not available ter-ade 
        then do:
            log-manager:write-message (substitute ('nao encontrado termo de adesao com chave &1/&2', ter-ade.cd-modalidade, ter-ade.nr-ter-adesao ),'ERROR').
            next.
        end.
        
        define variable in-codigo-contratante as integer no-undo.         
                                      
        if notaserv.in-tipo-nota    = 0
        or notaserv.in-tipo-nota    = 5        
        then do:
            if ter-ade.in-contratante-mensalidade   = 0 
            then in-codigo-contratante  = propost.cd-contratante.
            else in-codigo-contratante  = propost.cd-contrat-origem.            
        end.
        
        if notaserv.in-tipo-nota    = 1
        or notaserv.in-tipo-nota    = 3
        or notaserv.in-tipo-nota    = 8
        or notaserv.in-tipo-nota    = 9
        then do:
            if ter-ade.in-contratante-custo-op  = 0 
            then in-codigo-contratante  = propost.cd-contratante.
            else in-codigo-contratante  = propost.cd-contrat-origem.            
        end.
        
        if notaserv.in-tipo-nota    = 2
        or notaserv.in-tipo-nota    = 7
        then do:
            if ter-ade.in-contratante-participacao  = 0 
            then in-codigo-contratante  = propost.cd-contratante.
            else in-codigo-contratante  = propost.cd-contrat-origem.            
        end.
        
        find first contrat no-lock
             where contrat.cd-contratante   = propost.cd-contratante.
        
        create XML_FATURAMENTO.
        assign in-id-fat                                        = in-id-fat + 1
               XML_FATURAMENTO.CHAVE_SISTEMA                    = RegistroPrimary (buffer notaserv:handle)
               XML_FATURAMENTO.CHAVE_SISTEMA_CONTRATO           = RegistroPrimary (buffer propost:handle)
               XML_FATURAMENTO.CHAVE_SISTEMA_RESPONSAVEL_FINANC = RegistroPrimary (buffer contrat:handle) 
               XML_FATURAMENTO.CODIGO                           = substitute ('&1 - &2/&3 - &4/&5',
                                                                              BuscaTipoNotaServico(notaserv.in-tipo-nota),
                                                                              notaserv.cd-modalidade,
                                                                              propost.nr-proposta,
                                                                              string (notaserv.mm-referencia, '99'),
                                                                              string (notaserv.aa-referencia, '9999'))
               XML_FATURAMENTO.TIPO_FATURAMENTO                 = notaserv.in-tipo-nota
               XML_FATURAMENTO.ANO                              = notaserv.aa-referencia
               XML_FATURAMENTO.MES                              = notaserv.mm-referencia
               XML_FATURAMENTO.VALOR_TOTAL                      = notaserv.vl-total
               XML_FATURAMENTO.DATA_GERACAO                     = notaserv.dt-emissao
               XML_FATURAMENTO.DATA_VENCIMENTO                  = notaserv.dt-vencimento. 
               
        for each fatueven no-lock
           where fatueven.cd-modalidade         = notaserv.cd-modalidade
             and fatueven.nr-ter-adesao         = notaserv.nr-ter-adesao
             and fatueven.aa-referencia         = notaserv.aa-referencia
             and fatueven.mm-referencia         = notaserv.mm-referencia             
             and fatueven.nr-sequencia          = notaserv.nr-sequencia
             and fatueven.cd-evento             > 0
             and fatueven.cd-tipo-cob          >= 0
             and fatueven.cd-contratante        = notaserv.cd-contratante
             and fatueven.cd-contratante-origem = notaserv.cd-contratante-origem:
                 
            find first evenfatu no-lock
             use-index evenfat1
                 where evenfatu.cd-evento       = fatueven.cd-evento
                   and evenfatu.in-entidade     = "FT".

            /* Considera apenas eventos programados */
            if evenfatu.in-classe-evento       <> "M"
            or evenfatu.lg-ind-usu              = yes
            then do:
                next.
            end.

            assign dc-valor-evento  = fatueven.vl-evento.

            if not evenfatu.lg-cred-deb then assign dc-valor-evento = dc-valor-evento * -1.

            create XML_EVENTO_EXTRA.
            assign XML_EVENTO_EXTRA.XML_FATURAMENTO_id      = recid (XML_FATURAMENTO)                   
                   XML_EVENTO_EXTRA.CHAVE_SISTEMA           = RegistroPrimary (buffer fatueven:handle)
                   XML_EVENTO_EXTRA.CHAVE_SISTEMA_EVENTO    = RegistroPrimary (buffer evenfatu:handle)
                   XML_EVENTO_EXTRA.VALOR_TOTAL             = dc-valor-evento
                   XML_EVENTO_EXTRA.CODIGO                  = substitute ('Evento &1', evenfatu.ds-evento).
        end.

        for each usuario
           fields (cd-modalidade
                   nm-usuario
                   nr-proposta
                   nr-ter-adesao
                   cd-usuario) no-lock 
           where usuario.cd-modalidade          = propost.cd-modalidade
             and usuario.nr-proposta            = propost.nr-proposta,
            each vlbenef no-lock
           where vlbenef.cd-modalidade          = notaserv.cd-modalidade
             and vlbenef.nr-ter-adesao          = notaserv.nr-ter-adesao
             and vlbenef.aa-referencia          = in-ano
             and vlbenef.mm-referencia          = in-mes
             and vlbenef.cd-usuario             = usuario.cd-usuario        
             and vlbenef.aa-referencia          = notaserv.aa-referencia
             and vlbenef.mm-referencia          = notaserv.mm-referencia
             and vlbenef.nr-sequencia           = notaserv.nr-sequencia,
           first evenfatu no-lock
           where evenfatu.cd-evento             = vlbenef.cd-evento
             and evenfatu.in-entidade           = 'FT':
                                              
            assign dc-valor-evento  = vlbenef.vl-usuario. 
                
            if not evenfatu.lg-cred-deb 
            then assign dc-valor-evento = dc-valor-evento * -1.
            
            
            create XML_FATURAMENTO_ITENS.
            assign XML_FATURAMENTO_ITENS.XML_FATURAMENTO_id         = recid (XML_FATURAMENTO)
                   XML_FATURAMENTO_ITENS.CHAVE_SISTEMA              = RegistroPrimary (buffer vlbenef:handle)
                   XML_FATURAMENTO_ITENS.CHAVE_SISTEMA_EVENTO       = RegistroPrimary (buffer evenfatu:handle)
                   XML_FATURAMENTO_ITENS.CHAVE_SISTEMA_BENEFICIARIO = RegistroPrimary (buffer usuario:handle)
                   XML_FATURAMENTO_ITENS.VALOR_TOTAL                = dc-valor-evento                                              
                   XML_FATURAMENTO_ITENS.CODIGO                     = replace (RegistroPrimary (buffer vlbenef:handle), ';',  '/').
        end.                    

        EnviarDados (dataset XML_FATURAMENTOS:handle).
        dataset XML_FATURAMENTOS:empty-dataset ().
        in-id-fat = 0.
        
    end.
    
    EnviarDados (dataset XML_FATURAMENTOS:handle).
    dataset XML_FATURAMENTOS:empty-dataset ().
    
end procedure.


function BuscaTipoNotaServico returns character 
    (in-tipo-nota as integer  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    case in-tipo-nota:
        when 0 then return 'Pre Pagamento'.
        when 1 then return 'Custo operacional'.
        when 2 then return 'Coparticipaá∆o sem guia'.
        when 3 then return 'Custo operacional outras unidades'.
        when 5 then return 'Complementar'.
        when 7 then return 'Coparticipaá∆o com guia'.
        when 8 then return 'Custo operacional com anteciapaá∆o'.
        when 9 then return 'Custo operacional com anteciapaá∆o outras unidades'.
        otherwise return ''.    
    end.        
end function.
