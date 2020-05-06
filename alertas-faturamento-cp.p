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
          

/*------------------------------------------------------------------------
    File        : alertas-faturamento.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Jan 11 14:37:58 BRST 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

define temp-table XML_ALERTA no-undo
    namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_CONTRATANTE as character 
    field CHAVE_SISTEMA_CONTRATO as character 
    field CHAVE_SISTEMA_BENEF as character 
    field CODIGO_UNIDADE_BENEF as integer 
    field CODIGO_CART_BENEF as character 
    field TITULO as character 
    field DESCRICAO as character 
    field VALOR as decimal 
    field ANO as integer 
    field MES as integer 
    field CHAVE_SISTEMA_FATURAMENTO as character .

define temp-table XML_DADOS_EXTRAS no-undo
    namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    field CAMPO as character 
    field VALOR as character 
    field XML_ALERTA_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_ALERTAS namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    for XML_ALERTA, XML_DADOS_EXTRAS
    parent-id-relation RELATION1 for XML_ALERTA, XML_DADOS_EXTRAS
        parent-id-field XML_ALERTA_id.




define variable CH_MENSAGEM_COPART_NAO_FATURADA
                                                as   character
                                                init "Coparticipaá∆o em movimento liberado pelo RC e n∆o faturada" no-undo.
define variable CH_MENSAGEM_CONTRATO_SEM_NOTASERV   
                                                as   character  
                                                init "Contrato ativo no per°odo mas sem nota de serviáo" no-undo.
define variable CH_MENSAGEM_NOTASERV_SEM_FATURA   
                                                as   character  
                                                init "Nota de serviáo n∆o possui fatura gerada" no-undo.
define variable CH_MENSAGEM_NOTASERV_VINCULADO_FATURA_INEXISTENTE   
                                                as   character  
                                                init "Nota de serviáo vinculado a fatura inexistente" no-undo.                                                
define variable CH_MENSAGEM_FATURA_NAO_INTEGRADA_FINANCEIRO 
                                                as   character  
                                                init "Fatura n∆o integrada no financeiro" no-undo.                                                       
define variable CH_MENSAGEM_FATURA_VINCULADO_TITULO_INEXISTENTE
                                                as   character  
                                                init "Fatura vinculada a t°tulo inexistente" no-undo.                                                                                            
define variable CH_MENSAGEM_MOVIMENTO_CUSTO_NAO_FATURADO
                                                as   character  
                                                init "Movimento de custo operacional liberado no contas e n∆o faturado" no-undo.                                                                                            
define variable CH_MENSAGEM_MOVIMENTO_INTERCAMBIO_NAO_FATURADO
                                                as   character  
                                                init "Movimento de intercÉmbio liberado no contas e n∆o faturado" no-undo.                                                                                            

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
  

/*
  DEFINICAO DE VARIAVEIS E TEMP-TABLES PARA PERMITIR A CUSTOMIZACAO DA UTILIZACAO DO PROCESSO DE REGRAS DE VALORIZACAO
*/

/* VARIAVEIS*/
def var cd-unidade-prest-hdvalidagp  as int         no-undo.
def var cd-prestador-hdvalidagp      as int         no-undo.
def var cd-unid-cart-hdvalidagp      as int         no-undo.
def var cd-carteira-hdvalidagp       as dec         no-undo.
def var lg-cpc-hdvalidagp            as log         no-undo. 
def var lg-erro-cpc-hdvalidagp       as log         no-undo.
def var in-tipo-val-hdvalidagp       as char        no-undo. 
def var lg-mens-tela-hdvalidagp      as log         no-undo. 

/* TEMP-TABLES */
def temp-table tmp-cpc-hdvalidagp-entrada no-undo
    field in-tipo-valor             as char 
    field cd-unidade-prest          as int
    field cd-prestador              as int 
    field cd-unidade-carteira       as int
    field cd-carteira-usuario       as dec
    field dt-atual                  as date
    field lg-utiliza-regras         as log
    field lg-crud-hdvalidagp        as log.


def temp-table tmp-cpc-hdvalidagp-saida no-undo
    field lg-utiliza-regras         as log.

assign lg-erro-cpc-hdvalidagp = no
       lg-cpc-hdvalidagp      = no.

select d.lg-ativo-cpc into lg-cpc-hdvalidagp from dzlibprx d
                                             where d.nm-ponto-chamada-cpc = "REGRA-VALOR"
                                               and d.nm-programa          = "HDVALIDAGP".

if lg-cpc-hdvalidagp = ?
then assign lg-cpc-hdvalidagp = no. 


if  lg-cpc-hdvalidagp
and search("cpc/cpc-hdvalidagp.p") = ?                                                                
and search("cpc/cpc-hdvalidagp.r") = ?                                                                
then do:             
        if lg-mens-tela-hdvalidagp
        then do:
                message "Ponto REGRA-VALOR ativo, mas programa cpc-hdvalidagp nao disponivel!"        
                            view-as alert-box title " Atencao !!! ".                                      
                    return.                        
             end.
        else assign lg-erro-cpc-hdvalidagp = yes. 
     end.


                                                    


 

define temp-table tmp-rtbuscatabela-entrada           no-undo                                                                  
    field in-tipo-tabela                              as char format "x(03)"   
    field dt-base-valor                               as date        
    field cd-modalidade                               as int
    field cd-plano                                    as int 
    field cd-tipo-plano                               as int
    field nr-ter-adesao                               as int 
    field cd-usuario                                  as int 
    field cd-local-atendimento                        as int 
    field cd-clinica                                  as int
    field cd-unidade-prestador-exec                   as int 
    field cd-prestador-exec                           as int
    field cd-tipo-vinculo                             as int 
    field cd-esp-prest-executante                     as int 
    field cd-modulo                                   as int
    field in-tipo-servico                             as char format "x(01)"
    field cd-grupo-serv                               as int 
    field cd-servico                                  as int
    field cd-transacao                                as int
    field cd-tipo-acomodacao                          as int 
    field cd-tipo-atendimento                         as int.

define temp-table tmp-rtbuscatabela-saida             no-undo
    field lg-erro                                     as log
    field cd-erro                                     as int 
    field id-regra                                    as int format 99999999
    field lg-altera-tab-qt-moeda                      as log
    field lg-altera-tab-mo-care                       as log
    field cd-tab-preco-proc                           like moviproc.cd-tab-preco-proc  
    field cd-tab-preco                                like moviproc.cd-tab-preco.
 
/*****************************************************************************
*    Programa .....: rtvalori.i                                              *
*    Data .........: 13/01/2004                                              *
*    Sistema ......: RT - Rotinas                                            *
*    Empresa ......: DZSET SOLUCOES E SISTEMAS                               *
*    Cliente ......: Cooperativas Medicas                                    *
*    Programador ..: RODRIGO R                                               *
*    Objetivo .....: Valorizacao do procedimento para RC e FT                *
*----------------------------------------------------------------------------*
*    Versao     DATA         RESPONSAVEL                                     *
*               13/01/2004   RODRIGO R                                       *
*****************************************************************************/
 
/* ------------------------------------- TEMP TABLE DE ENTRADA DE DADOS --- */ 
                                           
define temp-table tmp-rtvalori-entrada     no-undo                                                                  
    field in-evento-programa           as char format "x(06)"                                                               
    field in-tipo-valori               as char format "x(03)"                                                               
    field lg-mensagem-na-tela          as logical                                                                           
    field lg-sem-cobertura             as logical                                                                           
    field lg-urgencia                  like moviproc.lg-urgencia                                                            
    field lg-urgencia-cob              like moviproc.lg-urgencia                                                             
    field lg-anestesista               like moviproc.lg-anestesista                                                         
    field nr-rowid-precproc            as rowid                                                                             
    field nr-recid-precproc            as recid                                                                             
    field in-moeda                     as char format "x(03)"                                                               
    field in-nivel-prestador           like moviproc.in-nivel-prestador                                                     
    field cd-tab-preco-proc            like moviproc.cd-tab-preco-proc                                                      
    field cd-tab-preco                 like moviproc.cd-tab-preco                                                      
    field cd-porte-anestesico          like moviproc.cd-porte-anestesico                                                    
    field cd-via-acesso                like moviproc.cd-via-acesso                                                          
    field cd-esp-amb                   like moviproc.cd-esp-amb                                                             
    field cd-grupo-proc-amb            like moviproc.cd-grupo-proc-amb                                                      
    field cd-procedimento              like moviproc.cd-procedimento                                                        
    field dv-procedimento              like moviproc.dv-procedimento                                                        
    field qt-procedimento              like moviproc.qt-procedimento                                                        
    field qt-repasse                   like moviproc.qt-repasse                                                             
    field dt-base-valor                like moviproc.dt-base-valor                                                          
    field qt-faixa-participacao        like fxparpro.qt-faixa-inicial                                                       
    field cd-transacao                 like moviproc.cd-transacao                                                           
    field dt-anoref                    like moviproc.dt-anoref                                                              
    field nr-perref                    like moviproc.nr-perref                                                              
    field cd-unidade-prestador-exec    like moviproc.cd-unidade-prestador                                                   
    field cd-prestador-exec            like moviproc.cd-prestador                                                           
    field cd-esp-prest-executante      like moviproc.cd-esp-prest-executante                                                
    field nr-rowid-proposta            as rowid                                                                             
    field nr-rowid-usuario             as rowid                                                                             
    field nr-rowid-unicamco            as rowid                                                                             
    field nr-rowid-out-uni             as rowid                                                                             
    field lg-guia                      as logical                                                                           
    field cd-modulo                    like mod-cob.cd-modulo                                                               
    field cd-local-atendimento         like locaaten.cd-local-atendimento                                                   
    field cd-clinica                   like moviproc.cd-clinica                                                             
    field cd-cid                       like docrecon.cd-cid
    field hr-realizacao                as char format "x(08)"
    field dt-realizacao                like moviproc.dt-realizacao
    field nr-rowid-docrecon            as rowid
    field dt-internacao                like docrecon.dt-internacao
    field hr-internacao                like docrecon.hr-internacao 
    field dt-alta                      like docrecon.dt-alta       
    field hr-alta                      like docrecon.hr-alta
    field dt-entrada-movimento         as date
    field cd-unidade-solicitante       as integer format "9999" 
    field cd-prestador-solicitante     as integer format "99999999"
    field cd-tipo-vinculo              like moviproc.cd-tipo-vinculo
    field id-regra                     as int
    field cd-pos-equipe                like moviproc.cd-pos-equipe.
                                                                                                                           
/* ----------------------------------------- TEMP TABLE DE SAIDA DE DADOS --- */                                           
def temp-table tmp-rtvalori-saida       no-undo                                                                             
    field lg-undo-retry                as logical                                                                         
    field ds-mensagem                  as char format "x(75)"                                                             
    field vl-honorarios                like moviproc.vl-honorarios-medicos                                                
    field vl-operacional               like moviproc.vl-operacional                                                       
    field vl-filme                     like moviproc.vl-filme                                                             
    field cd-moeda                     like precproc.cd-moeda-cop-ele
    field qt-moeda                     like moviproc.qt-moeda
    field vl-moeda                     like moviproc.vl-moeda
    field pc-aplicar                   as decimal
    field cd-procedimento-assoc          as int format 99999999
    field vl-principal-proc-assoc      like moviproc.vl-principal
    field pc-proced-aplicar              as decimal
    field vl-honorarios-original       like moviproc.vl-honorarios-medicos                                                
    field vl-operacional-original      like moviproc.vl-operacional                                                       
    field vl-filme-original            like moviproc.vl-filme
    field cdn-regra                     as int format 99999999
    field cd-tab-preco-proc            like moviproc.cd-tab-preco-proc  
    field cd-tab-preco                 like moviproc.cd-tab-preco
    field qt-repasse                   like moviproc.qt-repasse
    field cdd-def-audit                as dec  /* -- Id Deflatores -- */
    field val-perc-def                 as dec. /* -- Percentual Deflator -- */
    
/* ------------------------------------------------------------------- EOF -- */   



 
/******************************************************************************
*   Programa .....: rtclpart.i                                                *
*   Data .........: 24/02/2003                                                *
*   Sistema ......: RT - Rotina Padrao                                        *
*   Empresa ......: DZSET SOLUCOES E SISTEMAS                                 *
*   Cliente ......: Cooperativas Medicas                                      *
*   Programador ..: RODRIGO R                                                 *
*   Objetivo .....: Definicao de temp-table para rotina RTCLPART.P            *
*-----------------------------------------------------------------------------*
*    Versao     DATA         RESPONSAVEL                                      *
*               24/02/2003   RODRIGO R                                        *
******************************************************************************/

/* -------------------------------------- TEMP TABLE DE ENTRADA DE DADOS --- */
def temp-table tmp-rtclpart-entrada            no-undo
    field in-evento-programa                   as char format "x(06)"
    field lg-mensagem-na-tela                  as logical
    field lg-urgencia                          as logical
    field lg-sem-cobertura                     as logical
    field nr-rowid-usuario                     as rowid
    field nr-rowid-proposta                    as rowid
    field nr-rowid-precproc                    as rowid
    field nr-rowid-movto                       as rowid
    field cd-modulo                            like mod-cob.cd-modulo
    field cd-forma-pagto-cob                   like formpaga.cd-forma-pagto
    field in-tipo-movimento                    as char format "x(01)"
    field cd-grupo-proc                        like ambproce.cd-grupo-proc       
    field cd-amb                               like pl-mo-am.cd-amb             
    field cd-tipo-insumo                       like insumos.cd-tipo-insumo        
    field cd-insumo                            like insumos.cd-insumo             
    field vl-completo-do-movimento             like mov-insu.vl-insumo
    field qt-movimento                         like mov-insu.qt-insumo           
    field qt-faixa-participacao                like fxparpro.qt-faixa-inicial
    field dt-base-valor                        like mov-insu.dt-base-valor       
    field cd-transacao                         like moviptmp.cd-transacao
    field dt-anoref                            like moviptmp.dt-anoref           
    field nr-perref                            like moviptmp.nr-perref
    field cd-unidade-prestador-exec            like moviptmp.cd-unidade-prestador
    field cd-prestador-exec                    like moviptmp.cd-prestador
    field cd-esp-prest-executante              like moviptmp.cd-esp-prest-executante
    field vl-honorario                         like moviproc.vl-honorarios-medicos
    field vl-operacional                       like moviproc.vl-operacional      
    field vl-filme                             like moviproc.vl-filme
    field cd-local-atendimento                 like locaaten.cd-local-atendimento
    field cd-clinica                           like moviproc.cd-clinica
    field lg-simulacao                         as log
    field in-modulo-execucao                   as char format "x(03)"
    field lg-recalcula-percentual              as log init yes
    field aa-guia-atendimento                  like guiautor.aa-guia-atendimento
    field nr-guia-atendimento                  like guiautor.aa-guia-atendimento
    field lg-fratura                           as log init no
    field cd-tipo-guia                         like tip-guia.cd-tipo-guia
    field nr-recid-unicamco                    as recid
    field nr-recid-out-uni                     as recid
    field cd-unidade-principal                 like docrecon.cd-unidade-principal
    field cd-prestador-principal               like docrecon.cd-prestador-principal
    field cd-vinculo-prest-exe                 like previesp.cd-vinculo
        field id-regra-copartcipacao               as int
    field lg-movto-internacao                  as log
    field dt-postagem-arq                      like mov-insu.dt-base-valor
    field pc-desc-hono                         as dec
    field pc-desc-operacional                  as dec
    field pc-desc-filme                        as dec.

/* ----------------------------------------- TEMP TABLE DE SAIDA DE DADOS --- */
def temp-table tmp-rtclpart-saida      no-undo
    field lg-undo-retry                as logical
    field ds-mensagem-relatorio        as char format "x(75)"
    field vl-taxa-participacao         like mov-insu.vl-desconto-prestador
    field pc-taxa-participacao         like fxparpro.pc-part-cob-urg
    field pc-faixa-part                as dec format ">>9.999"        extent 100
    field qt-faixa-part                as dec format ">>>,>>>,>>9.99" extent 100 
    field vl-faixa-part                as dec format ">>>,>>>,>>9.99" extent 100
    field qt-movto                     as int                         extent 100
    field id-regra-coparticipacao      as int
    field lg-cob-pag                   as log. /* Faturamento no / Pagamento yes */


/*-----------------------------------------------------------------------------*/
                /* -------------- CALCULO DA PARTICIPACAO --- */

define buffer b-docrecon for docrecon.

/* ************************  Function Prototypes ********************** */

/* **********************  Internal Procedures  *********************** */
procedure Executa:
    define input  parameter table for temp-parametro-entrada.
    define input  parameter table for temp-parametro-periodo.
 
    define variable ch-referencia               as   character  no-undo.
    define variable in-ano                      as   integer    no-undo.
    define variable in-mes                      as   integer    no-undo.
    define variable dt-base                     as   date       no-undo.
    
    find first temp-parametro-entrada.
    find first paramecp no-lock.
    
    for each temp-parametro-periodo:

        run ProcessaMesAno (input  temp-parametro-periodo.in-mes,
                            input  temp-parametro-periodo.in-ano).
    end.
end procedure.


procedure LeInsumos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-ano-periodo      as   integer        no-undo.
    define input  parameter in-numero-periodo   as   integer        no-undo.
    define input  parameter in-ano              as   integer        no-undo.
    define input  parameter in-mes              as   integer        no-undo.
    
    define variable in-conta                    as   integer        no-undo.
    define variable lg-glosa-parcial            as   logical        no-undo.
    define variable in-qt-insumo                as   integer        no-undo.
    

    for each mov-insu no-lock
       where mov-insu.cd-unidade                = paramecp.cd-unimed
         and mov-insu.in-liberado-contas        = "1"
         and mov-insu.in-liberado-pagto         = "1"
         and mov-insu.dt-anoref                 = in-ano-periodo
         and mov-insu.nr-perref                 = in-numero-periodo
         and mov-insu.in-liberado-faturamento   = "0":
            
        if mov-insu.cd-unidade-carteira    <> paramecp.cd-unimed
        then do:
            next.
        end.             
                
        if  mov-insu.cd-tipo-cob                = 0
        and mov-insu.cd-forma-pagto-cob         = 1
        then next.
            
        if mov-insu.cd-tipo-cob     = 3
        or mov-insu.cd-tipo-cob     = 5
        or mov-insu.cd-tipo-cob     = 6
        or mov-insu.cd-tipo-cob     = 7
        then next.
                 
        if available propost then release propost.
        if available contrat then release contrat.      
        if available usuario then release usuario.      
        
        if mov-insu.lg-cobrado-participacao then next.
                                           
        /* copart no prestador */
        if (   mov-insu.in-cobra-participacao   = 03
            or mov-insu.in-cobra-participacao   = 09)
        then next.
        
        /* copart no prestador com prestador base */
        if  (   mov-insu.in-cobra-participacao  = 04
             or mov-insu.in-cobra-participacao  = 06
             or mov-insu.in-cobra-participacao  = 08)
        and mov-insu.cd-unidade-pagamento       = paramecp.cd-unimed
        then next.
        
        if  mov-insu.in-cobra-participacao  = 07
        and mov-insu.cd-unidade-pagamento   = paramecp.cd-unimed
        then do:
            
            find first preserv no-lock
             /* use-index preserv1 */            
                 where preserv.cd-unidade   = mov-insu.cd-unidade-prestador
                   and preserv.cd-prestador = mov-insu.cd-prestador
                       no-error.
            
            if not available preserv
            then do:
                log-manager:write-message (substitute ('nao encontrado prestador com a chave &1/&2', 
                                                       mov-insu.cd-unidade-prestador,
                                                       mov-insu.cd-prestador),
                                           'DEBUG').
                next.                                           
            end.                           
            
            if preserv.lg-recolhe-participacao then next.
        end.
                                          
        find first propost no-lock
             where propost.cd-modalidade    = mov-insu.cd-modalidade
               and propost.nr-ter-adesao    = mov-insu.nr-ter-adesao
                   no-error.

        if not available propost then next.                   

        /* proposta nao cobra copart */
        if propost.cd-tipo-participacao    <> 2
        then next.                                    
        
        find first usuario no-lock
             where usuario.cd-modalidade    = propost.cd-modalidade
               and usuario.nr-proposta      = propost.nr-proposta
               and usuario.cd-usuario       = mov-insu.cd-usuario
                   no-error.                            
        if not available usuario then next.
        
        if usuario.lg-cobra-fator-moderador = no then next.
                
        lg-glosa-parcial = no.
        in-qt-insumo = 0.
        
        if mov-insu.cd-classe-erro > 0
        then do:
            if can-find (first movrcglo
                         where movrcglo.cd-unidade            = mov-insu.cd-unidade           
                           and movrcglo.cd-unidade-prestadora = mov-insu.cd-unidade-prestadora
                           and movrcglo.cd-transacao          = mov-insu.cd-transacao         
                           and movrcglo.nr-serie-doc-original = mov-insu.nr-serie-doc-original
                           and movrcglo.nr-doc-original       = mov-insu.nr-doc-original      
                           and movrcglo.nr-doc-sistema        = mov-insu.nr-doc-sistema       
                           and movrcglo.nr-processo           = mov-insu.nr-processo          
                           and movrcglo.nr-seq-digitacao      = mov-insu.nr-seq-digitacao     
                           and (     movrcglo.cd-classe-erro <> 10
                                 and movrcglo.cd-classe-erro <> 23
                                 and movrcglo.cd-classe-erro <> 24
                                 and movrcglo.cd-classe-erro <> 44
                                 and movrcglo.cd-classe-erro <> 45
                                 and movrcglo.cd-classe-erro <> 126))
            then.
            else do:
                if mov-insu.val-quant-insumo-dispon > 0 
                then assign lg-glosa-parcial   = yes
                            in-qt-insumo       = mov-insu.qt-insumo - mov-insu.val-quant-insumo-dispon.
            end.
        end.          
                         
        find first docrecon no-lock 
             where docrecon.cd-unidade              = mov-insu.cd-unidade           
               and docrecon.cd-unidade-prestadora   = mov-insu.cd-unidade-prestadora
               and docrecon.cd-transacao            = mov-insu.cd-transacao
               and docrecon.nr-serie-doc-original   = mov-insu.nr-serie-doc-original
               and docrecon.nr-doc-original         = mov-insu.nr-doc-original
               and docrecon.nr-doc-sistema          = mov-insu.nr-doc-sistema.
                                                      
        if docrecon.lg-guia
        then do:
            find first guiautor no-lock  
                 where guiautor.cd-unidade          = docrecon.cd-unidade
                   and guiautor.aa-guia-atendimento = docrecon.aa-guia-atendimento
                   and guiautor.nr-guia-atendimento = docrecon.nr-guia-atendimento
                       no-error.          
            
            if  available guiautor
            and guiautor.lg-imp-recibo
            then do:                    
                if  guiautor.in-liberado-guias <> "3"
                and guiautor.in-liberado-guias <> "8"
                and (   in-qt-insumo       <= mov-insu.dec-11
                     or moviproc.dec-11     = 0)
                then next.
            end.                                 
        end.
        else do:
            if  mov-insu.in-cobra-participacao  = 2
            then do:
                if mov-insu.cd-unidade-pagamento  <> paramecp.cd-unimed 
                then next.
            end.
            else do:
                /* DENISE nao sei o que botar aqui, FP0711c indep, linha 3089 */
                if mov-insu.cd-tipo-cob = 6
                then .
                else next.
            end.
            
            if mov-insu.in-cobra-participacao   = 5
            then do:
                if mov-insu.cd-unidade-pagamento <> paramecp.cd-unimed
                then do:
                    /* DENISE nao sei o que botar aqui, FP0711c indep, linha 3109 */
                    if mov-insu.cd-tipo-cob    <> 6
                    then . 
                    else next. 
                end. 
            end.
        end.

        create XML_ALERTA.
        assign in-conta                             = in-conta + 1
               XML_ALERTA.CHAVE_SISTEMA             = "COP" + RegistroPrimary (buffer mov-insu:handle)
               XML_ALERTA.CODIGO                    = if available propost
                                                      then substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                                                      else ''
               XML_ALERTA.TITULO                    = CH_MENSAGEM_COPART_NAO_FATURADA
               XML_ALERTA.DESCRICAO                 = substitute ("Documento: &1/&2/&3/&4/&5/&6, Insumo: &7/&8, sequencia &9",
                                                                  mov-insu.cd-unidade,
                                                                  mov-insu.cd-unidade-prestadora,
                                                                  mov-insu.cd-transacao,
                                                                  mov-insu.nr-serie-doc-original,
                                                                  mov-insu.nr-doc-original,
                                                                  mov-insu.nr-doc-sistema,
                                                                  string (mov-insu.cd-tipo-insumo, '99'),
                                                                  string (mov-insu.cd-insumo, '99999999'),
                                                                  mov-insu.nr-seq-digitacao)
               XML_ALERTA.ANO                       = in-ano
               XML_ALERTA.MES                       = in-mes               
               XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
               XML_ALERTA.CHAVE_SISTEMA_BENEF       = RegistroPrimary (buffer usuario:handle) 
               XML_ALERTA.CODIGO_CART_BENEF         = string (mov-insu.cd-carteira-usuario, '9999999999999')
               XML_ALERTA.CODIGO_UNIDADE_BENEF      = mov-insu.cd-unidade-carteira
               XML_ALERTA.VALOR                     = mov-insu.vl-real-pago.
               

        if in-conta = 100
        then do:
            EnviarDados (dataset XML_ALERTAS:handle).
            dataset XML_ALERTAS:empty-dataset ().
            in-conta = 0.            
        end.                                   
    end.
end procedure.


procedure SimulaCoparticipacao:
    
    define output parameter dc-valor-copart             as   decimal        no-undo.
    define output parameter lg-erro                     as   logical        no-undo.

    define variable in-cd-tipo-cob                      as   integer        no-undo.
    define variable ch-cobertura                        as   character      no-undo.
    define variable ch-moeda                            as   character      no-undo.
    define variable in-id-regra                         as   integer        no-undo.
    define variable ch-tabela-preco-cobranca            as   character      no-undo.
    
    empty temp-table tmp-rtbuscatabela-entrada.
    empty temp-table tmp-rtbuscatabela-saida.
    empty temp-table tmp-rtvalori-entrada.
    empty temp-table tmp-rtvalori-saida.

    
    create tmp-rtbuscatabela-entrada.
    assign tmp-rtbuscatabela-entrada.in-tipo-tabela            = "COB"
           tmp-rtbuscatabela-entrada.dt-base-valor             = moviproc.dt-base-valor
           tmp-rtbuscatabela-entrada.cd-modalidade             = if available propost then propost.cd-modalidade else 0    
           tmp-rtbuscatabela-entrada.cd-plano                  = if available propost then propost.cd-plano else 0
           tmp-rtbuscatabela-entrada.cd-tipo-plano             = if available propost then propost.cd-tipo-plano else 0
           tmp-rtbuscatabela-entrada.nr-ter-adesao             = if available propost then propost.nr-ter-adesao else 0   
           tmp-rtbuscatabela-entrada.cd-usuario                = if available usuario then usuario.cd-usuario else 0 
           tmp-rtbuscatabela-entrada.cd-local-atendimento      = docrecon.cd-local-atendimento
           tmp-rtbuscatabela-entrada.cd-clinica                = docrecon.cd-clinica
           tmp-rtbuscatabela-entrada.cd-unidade-prestador-exec = preserv.cd-unidade
           tmp-rtbuscatabela-entrada.cd-prestador-exec         = preserv.cd-prestador
           tmp-rtbuscatabela-entrada.cd-tipo-vinculo           = moviproc.cd-tipo-vinculo
           tmp-rtbuscatabela-entrada.cd-esp-prest-executante   = moviproc.cd-esp-prest-executante
           tmp-rtbuscatabela-entrada.cd-modulo                 = moviproc.cd-modulo
           tmp-rtbuscatabela-entrada.in-tipo-servico           = "P"
           tmp-rtbuscatabela-entrada.cd-grupo-serv             = ambproce.cd-grupo-proc
           tmp-rtbuscatabela-entrada.cd-servico                = integer (substitute ('&1&2&3&4',
                                                                                      string (moviproc.cd-esp-amb, '99'),
                                                                                      string (moviproc.cd-grupo-proc-amb, '99'),
                                                                                      string (moviproc.cd-procedimento, '999'),
                                                                                      string (moviproc.dv-procedimento, '99')))
           tmp-rtbuscatabela-entrada.cd-transacao              = tranrevi.cd-transacao
           tmp-rtbuscatabela-entrada.cd-tipo-acomodacao        = docrecon.tp-acomod
           tmp-rtbuscatabela-entrada.cd-tipo-atendimento       = docrecon.tp-atend.


    run rtp/rtbuscatabelas.p (input  table tmp-rtbuscatabela-entrada,
                              output table tmp-rtbuscatabela-saida) no-error.
    
    if error-status:error
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtbuscatabelas: &1 - &2',
                                               error-status:get-number (1),
                                               error-status:get-message (1)),'ERROR') no-error.
        lg-erro = yes.
        return.
    end.
    
    find first tmp-rtbuscatabela-saida no-error.

    if not available tmp-rtbuscatabela-saida
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtbuscatabelas (sem tabela de saida)'),'ERROR') no-error.
        lg-erro = yes.
        return.        
    end.

    if tmp-rtbuscatabela-saida.lg-erro
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtbuscatabelas (lg-erro)'),'ERROR') no-error.
        lg-erro = yes.
        return.        
    end.
                

    if tmp-rtbuscatabela-saida.lg-altera-tab-qt-moeda
    then do:
        assign ch-tabela-preco-cobranca = tmp-rtbuscatabela-saida.cd-tab-preco-proc.
    end.                
                
    assign in-id-regra   = tmp-rtbuscatabela-saida.id-regra.
    

    find first precproc no-lock
         where precproc.cd-tab-preco    = moviproc.cd-tab-preco-cob
           and precproc.cd-forma-pagto  = moviproc.cd-forma-pagto-cob
           and precproc.dt-limite      >= moviproc.dt-realizacao.    
                

    if  not available propost                                                                     
    and moviproc.cd-unidade-prestador = paramecp.cd-unimed                                       
    then assign in-cd-tipo-cob  = 04                                                             
                ch-cobertura    = "INTFD".                                                       
                                                                                                
    else assign in-cd-tipo-cob  = 00                                                             
                ch-cobertura    = "NORMA".         
                           
                
    if (   moviproc.in-cobra-participacao   = 03                                                           
        or moviproc.in-cobra-participacao   = 04                                                           
        or moviproc.in-cobra-participacao   = 06                                                           
        or moviproc.in-cobra-participacao   = 07)                                                          
    and  moviproc.cd-unidade-prestador      = paramecp.cd-unimed                                              
    and  preserv.lg-recolhe-participacao                                                                  
    then do:    /* ----------------------- COBRA PARTICIPACAO DO PRESTADOR --- */                         
                                                                                                           
            /* ------------------------------ INDICA MOEDA PARA VALORIZACAO --- */                         
        if ch-cobertura = "NORMA"                                                                
        or ch-cobertura = "INTFD"                                                                
        then do:                                                                                       
            if  moviproc.lg-trab-cooperado                                                         
            then assign ch-moeda    = "MCC".                                                              
            else assign ch-moeda    = "MPC".                                                              
        end.                                                                                      
        else do:                                                                                       
            if moviproc.lg-trab-cooperado                                                         
            then assign ch-moeda    = "ICC".                                                              
            else assign ch-moeda    = "IPC".                                                              
         end. 
    end.    
    
    create tmp-rtvalori-entrada.
    assign tmp-rtvalori-entrada.in-evento-programa          = 'INCLUI'
           tmp-rtvalori-entrada.in-tipo-valori              = 'COB'
           tmp-rtvalori-entrada.lg-mensagem-na-tela         = no
           tmp-rtvalori-entrada.lg-sem-cobertura            = moviproc.lg-sem-cobertura
           tmp-rtvalori-entrada.lg-urgencia                 = moviproc.lg-adicional-urgencia /* rtvlperc.2501 */
           tmp-rtvalori-entrada.lg-urgencia-cob             = moviproc.log-11
           tmp-rtvalori-entrada.lg-anestesista              = moviproc.lg-anestesista
           tmp-rtvalori-entrada.nr-rowid-precproc           = rowid (precproc)
           tmp-rtvalori-entrada.in-moeda                    = ch-moeda
           tmp-rtvalori-entrada.in-nivel-prestador          = moviproc.in-nivel-prestador                   
           tmp-rtvalori-entrada.cd-tab-preco-proc           = moviproc.cd-tab-preco-proc                    
           tmp-rtvalori-entrada.cd-porte-anestesico         = moviproc.cd-porte-anestesico              
           tmp-rtvalori-entrada.cd-esp-amb                  = moviproc.cd-esp-amb                           
           tmp-rtvalori-entrada.cd-grupo-proc-amb           = moviproc.cd-grupo-proc-amb                    
           tmp-rtvalori-entrada.cd-procedimento             = moviproc.cd-procedimento                      
           tmp-rtvalori-entrada.dv-procedimento             = moviproc.dv-procedimento                      
           tmp-rtvalori-entrada.qt-procedimento             = moviproc.qt-procedimentos                     
           tmp-rtvalori-entrada.qt-repasse                  = moviproc.qt-repasse-cob                            
           tmp-rtvalori-entrada.dt-base-valor               = moviproc.dt-base-valor                     
           tmp-rtvalori-entrada.qt-faixa-participacao       = moviproc.qt-faixa-participacao                                                   
           tmp-rtvalori-entrada.cd-transacao                = moviproc.cd-transacao                                 
           tmp-rtvalori-entrada.dt-anoref                   = moviproc.dt-anoref                                               
           tmp-rtvalori-entrada.nr-perref                   = moviproc.nr-perref                                                   
           tmp-rtvalori-entrada.cd-unidade-prestador-exec   = moviproc.cd-unidade-prestador   
           tmp-rtvalori-entrada.cd-prestador-exec           = moviproc.cd-prestador                          
           tmp-rtvalori-entrada.cd-esp-prest-executante     = moviproc.cd-esp-prest-executante  
           tmp-rtvalori-entrada.nr-rowid-proposta           = if available propost then rowid (propost) else ?            
           tmp-rtvalori-entrada.nr-rowid-usuario            = if available usuario then rowid (usuario) else ?             
           tmp-rtvalori-entrada.nr-rowid-unicamco           = if available unicamco then rowid (unicamco) else ?            
           tmp-rtvalori-entrada.nr-rowid-out-uni            = if available out-uni then rowid(out-uni) else ?             
           tmp-rtvalori-entrada.lg-guia                     = docrecon.lg-guia            
           tmp-rtvalori-entrada.cd-modulo                   = moviproc.cd-modulo                
           tmp-rtvalori-entrada.cd-local-atendimento        = docrecon.cd-local-atendimento 
           tmp-rtvalori-entrada.cd-clinica                  = docrecon.cd-clinica           
           tmp-rtvalori-entrada.cd-cid                      = docrecon.cd-cid               
           tmp-rtvalori-entrada.hr-realizacao               = moviproc.hr-realizacao
           tmp-rtvalori-entrada.dt-realizacao               = moviproc.dt-realizacao
           tmp-rtvalori-entrada.cd-tipo-vinculo             = 0
           tmp-rtvalori-entrada.cd-unidade-solicitante      = docrecon.cd-unidade-solicitante   
           tmp-rtvalori-entrada.cd-prestador-solicitante    = docrecon.cd-prestador-solicitante 
           tmp-rtvalori-entrada.cd-tipo-vinculo             = moviproc.cd-tipo-vinculo            
           tmp-rtvalori-entrada.cd-pos-equipe               = moviproc.cd-pos-equipe              
           tmp-rtvalori-entrada.id-regra                    = in-id-regra.       
       
       
    run rtp/rtvalori.p (input  table tmp-rtvalori-entrada,                               
                        output table tmp-rtvalori-saida) no-error.
                        
    if error-status:error
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtvalori: &1 - &2',
                                               error-status:get-number (1),
                                               error-status:get-message(1)),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end.       

    find first tmp-rtvalori-saida no-error.
    if not available tmp-rtvalori-saida
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtvalori (sem tabela de sa°da)'),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end.                              

    if tmp-rtvalori-saida.lg-undo-retry
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtvalori (undo retry):  &1',
                                               tmp-rtvalori-saida.ds-mensagem),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end.
    
    
    
    create tmp-rtclpart-entrada.                                   
    assign tmp-rtclpart-entrada.in-evento-programa        = "INCLUI"              
          tmp-rtclpart-entrada.lg-mensagem-na-tela       = no      
          tmp-rtclpart-entrada.lg-urgencia               = moviproc.lg-adicional-urgencia     
          tmp-rtclpart-entrada.lg-sem-cobertura          = moviproc.lg-sem-cobertura       
          tmp-rtclpart-entrada.nr-rowid-usuario          = rowid(usuario)
          tmp-rtclpart-entrada.nr-rowid-proposta         = rowid(propost)
          tmp-rtclpart-entrada.nr-rowid-precproc         = rowid(precproc)
          tmp-rtclpart-entrada.cd-modulo                 = moviproc.cd-modulo      
          tmp-rtclpart-entrada.cd-forma-pagto-cob        = moviproc.cd-forma-pagto-cob      
          tmp-rtclpart-entrada.in-tipo-movimento         = 'P'
          tmp-rtclpart-entrada.vl-completo-do-movimento  = tmp-rtvalori-saida.vl-honorarios + tmp-rtvalori-saida.vl-filme + tmp-rtvalori-saida.vl-operacional       
          tmp-rtclpart-entrada.qt-movimento              = moviproc.qt-cobrado
          tmp-rtclpart-entrada.qt-faixa-participacao     = moviproc.qt-faixa-participacao
          tmp-rtclpart-entrada.dt-base-valor             = moviproc.dt-base-valor
          tmp-rtclpart-entrada.cd-transacao              = moviproc.cd-transacao
          tmp-rtclpart-entrada.dt-anoref                 = moviproc.dt-anoref
          tmp-rtclpart-entrada.nr-perref                 = moviproc.nr-perref
          tmp-rtclpart-entrada.cd-unidade-prestador-exec = moviproc.cd-unidade-prestador  
          tmp-rtclpart-entrada.cd-prestador-exec         = moviproc.cd-prestador
          tmp-rtclpart-entrada.cd-esp-prest-executante   = moviproc.cd-esp-prest-executante 
          tmp-rtclpart-entrada.vl-honorario              = tmp-rtvalori-saida.vl-honorarios
          tmp-rtclpart-entrada.vl-operacional            = tmp-rtvalori-saida.vl-operacional
          tmp-rtclpart-entrada.vl-filme                  = tmp-rtvalori-saida.vl-filme
          tmp-rtclpart-entrada.cd-local-atendimento      = docrecon.cd-local-atendimento
          tmp-rtclpart-entrada.cd-clinica                = docrecon.cd-clinica
          tmp-rtclpart-entrada.lg-simulacao              = yes
          tmp-rtclpart-entrada.in-modulo-execucao        = "FP"
          tmp-rtclpart-entrada.lg-recalcula-percentual   = no /* VERIFICAR */
          tmp-rtclpart-entrada.aa-guia-atendimento       = docrecon.aa-guia-atendimento
          tmp-rtclpart-entrada.nr-guia-atendimento       = docrecon.nr-guia-atendimento
          tmp-rtclpart-entrada.lg-fratura                = ?
          tmp-rtclpart-entrada.nr-recid-unicamco         = if   available unicamco
                                                           then recid(unicamco)
                                                           else ?
          tmp-rtclpart-entrada.nr-recid-out-uni          = ?
          tmp-rtclpart-entrada.cd-unidade-principal      = docrecon.cd-unidade-principal
          tmp-rtclpart-entrada.cd-prestador-principal    = docrecon.cd-prestador-principal
          tmp-rtclpart-entrada.cd-vinculo-prest-exe      = ?.
        
        assign tmp-rtclpart-entrada.cd-grupo-proc             = ambproce.cd-grupo-proc  
                      tmp-rtclpart-entrada.cd-amb                    = ambproce.cd-procedimento-completo
                      tmp-rtclpart-entrada.cd-tipo-insumo            = 0 
                      tmp-rtclpart-entrada.cd-insumo                 = 0
                      tmp-rtclpart-entrada.nr-rowid-movto            = rowid(moviproc)
                      tmp-rtclpart-entrada.pc-desc-hono              = moviproc.dec-11
                      tmp-rtclpart-entrada.pc-desc-operacional       = moviproc.dec-12
                      tmp-rtclpart-entrada.pc-desc-filme             = moviproc.dec-13.
                      
    run rtp/rtclpart.p (input  table tmp-rtclpart-entrada,
                        output table tmp-rtclpart-saida) no-error.
                        
    if error-status:error
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtclpart: &1 - &2',
                                               error-status:get-number (1),
                                               error-status:get-message(1)),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end.       

    find first tmp-rtclpart-saida no-error.
    if not available tmp-rtclpart-saida
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtclpart (sem tabela de sa°da)'),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end.                              

    if tmp-rtclpart-saida.lg-undo-retry
    then do:
        log-manager:write-message (substitute ('erro na execucao da rotina rtclpart (undo retry):  &1',
                                               tmp-rtclpart-saida.ds-mensagem-relatorio),'DEBUG') no-error.
        lg-erro = yes.
        return.                                               
    end. 
    
    assign dc-valor-copart  = tmp-rtclpart-saida.vl-taxa-participacao.
    
end procedure.



procedure LeProcedimentos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-ano-periodo      as   integer        no-undo.
    define input  parameter in-numero-periodo   as   integer        no-undo.
    define input  parameter in-ano              as   integer        no-undo.
    define input  parameter in-mes              as   integer        no-undo.
    
    define variable in-conta                    as   integer        no-undo.                        
    define variable lg-glosa-parcial            as   logical        no-undo.
    define variable in-qt-procedimento          as   integer        no-undo.

    for each moviproc no-lock 
       where moviproc.cd-unidade                = paramecp.cd-unimed
         and moviproc.in-liberado-contas        = "1"
         and moviproc.in-liberado-pagto         = "1"
         and moviproc.dt-anoref                 = perimovi.dt-anoref
         and moviproc.nr-perref                 = perimovi.nr-perref             
         and moviproc.in-liberado-faturamento   = "0"
         and moviproc.cd-forma-pagto-cob        = 2:
                         

        if available usuario then release usuario.
        if available propost then release propost.
        if available guiautor then release guiautor.
        if available docrecon then release docrecon.
        if available preserv then release preserv.          
        if available ambproce then release ambproce.   
        if available gru-pro then release gru-pro.            
                         
        if moviproc.cd-unidade-carteira    <> paramecp.cd-unimed
        then do:
            next.
        end.     
    
        if  moviproc.cd-tipo-cob                = 0
        and moviproc.cd-forma-pagto-cob         = 1
        then next.
        
        if moviproc.cd-tipo-cob     = 3
        or moviproc.cd-tipo-cob     = 5
        or moviproc.cd-tipo-cob     = 6
        or moviproc.cd-tipo-cob     = 7
        then next.
                             
        log-manager:write-message (substitute ('lendo moviproc &1', RegistroPrimary (buffer moviproc:handle)),'DEBUG').                     
                         
        if moviproc.lg-cobrado-participacao then next.
        
        /* copart no prestador */
        if (   moviproc.in-cobra-participacao   = 03
            or moviproc.in-cobra-participacao   = 09)
        then next.
        
        /* copart no prestador com prestador base */
        if  (   moviproc.in-cobra-participacao  = 04
             or moviproc.in-cobra-participacao  = 06
             or moviproc.in-cobra-participacao  = 08)
        and moviproc.cd-unidade-pagamento       = paramecp.cd-unimed
        then next.
                    
        if  moviproc.in-cobra-participacao  = 07
        and moviproc.cd-unidade-pagamento   = paramecp.cd-unimed
        then do:
            
            find first preserv no-lock
                 where preserv.cd-unidade   = moviproc.cd-unidade-prestador
                   and preserv.cd-prestador = moviproc.cd-prestador
                       no-error.
            
            if not available preserv
            then do:
                log-manager:write-message (substitute ('nao encontrado prestador com a chave &1/&2', 
                                           moviproc.cd-unidade-prestador,
                                                       moviproc.cd-prestador),
                                           'DEBUG').
                next.
            end.

            if preserv.lg-recolhe-participacao then next.
        end.

        find ambproce no-lock 
       where ambproce.cd-esp-amb        = moviproc.cd-esp-amb
         and ambproce.cd-grupo-proc-amb = moviproc.cd-grupo-proc-amb
         and ambproce.cd-procedimento   = moviproc.cd-procedimento
         and ambproce.dv-procedimento   = moviproc.dv-procedimento
             no-error.
      
        find gru-pro no-lock 
       where gru-pro.cd-grupo-proc  = ambproce.cd-grupo-proc
             no-error.                                  
                                          

        find first propost no-lock
             where propost.cd-modalidade    = moviproc.cd-modalidade
               and propost.nr-ter-adesao    = moviproc.nr-ter-adesao
                   no-error.
        if not available propost then next.                       

        /* proposta nao cobra copart */
        if propost.cd-tipo-participacao    <> 2
        then next.              
            
        find first usuario no-lock
             where usuario.cd-modalidade    = propost.cd-modalidade
               and usuario.nr-proposta      = propost.nr-proposta
               and usuario.cd-usuario       = moviproc.cd-usuario
                   no-error.
        if not available usuario then next.                   

        if usuario.lg-cobra-fator-moderador = no then next.

        if moviproc.lg-anestesista
        then do:
            if  moviproc.in-nivel-prestador     = 1
            and moviproc.in-resultado-divisao   = "2"
            then do:

                if available gru-pro
                and gru-pro.lg-cooperado 
                then next.
            end.
        end.

        if moviproc.cd-classe-erro > 0
        then do:
            if can-find (first movrcglo
                         where movrcglo.cd-unidade            = moviproc.cd-unidade           
                           and movrcglo.cd-unidade-prestadora = moviproc.cd-unidade-prestadora
                           and movrcglo.cd-transacao          = moviproc.cd-transacao         
                           and movrcglo.nr-serie-doc-original = moviproc.nr-serie-doc-original
                           and movrcglo.nr-doc-original       = moviproc.nr-doc-original      
                           and movrcglo.nr-doc-sistema        = moviproc.nr-doc-sistema       
                           and movrcglo.nr-processo           = moviproc.nr-processo          
                           and movrcglo.nr-seq-digitacao      = moviproc.nr-seq-digitacao     
                           and (   movrcglo.cd-classe-erro <> 10
                                 and movrcglo.cd-classe-erro <> 23
                                 and movrcglo.cd-classe-erro <> 24
                                 and movrcglo.cd-classe-erro <> 44
                                 and movrcglo.cd-classe-erro <> 45
                                 and movrcglo.cd-classe-erro <> 126))
            then.
            else do:
                if moviproc.qti-quant-proced-dispon > 0 
                then assign lg-glosa-parcial = yes
                            in-qt-procedimento = moviproc.qt-procedimentos - moviproc.qti-quant-proced-dispon.
            end.
        end.               
                    
        find first docrecon no-lock 
             where docrecon.cd-unidade              = moviproc.cd-unidade           
               and docrecon.cd-unidade-prestadora   = moviproc.cd-unidade-prestadora
               and docrecon.cd-transacao            = moviproc.cd-transacao
               and docrecon.nr-serie-doc-original   = moviproc.nr-serie-doc-original
               and docrecon.nr-doc-original         = moviproc.nr-doc-original
               and docrecon.nr-doc-sistema          = moviproc.nr-doc-sistema.
               
        if docrecon.lg-guia
        then do:
            find first guiautor no-lock  
                 where guiautor.cd-unidade          = docrecon.cd-unidade
                   and guiautor.aa-guia-atendimento = docrecon.aa-guia-atendimento
                   and guiautor.nr-guia-atendimento = docrecon.nr-guia-atendimento
                       no-error.          
            
            if  available guiautor
            and guiautor.lg-imp-recibo
            then do:                    
                if  guiautor.in-liberado-guias <> "3"
                and guiautor.in-liberado-guias <> "8"
                and (   in-qt-procedimento     <= moviproc.int-1
                     or moviproc.int-1            = 0)
                then next.
            end.                                 
        end.
        else do:
            if  moviproc.in-cobra-participacao  = 2
            then do:
                if moviproc.cd-unidade-pagamento  <> paramecp.cd-unimed 
                then next.
            end.
            else do:
                /* DENISE nao sei o que botar aqui, FP0711c indep */
                if moviproc.cd-tipo-cob    = 6
                then .
                else next.
            end.
            
            if moviproc.in-cobra-participacao   = 5
            then do:
                if moviproc.cd-unidade-pagamento <> paramecp.cd-unimed
                then do:
                    /* DENISE nao sei o que botar aqui, FP0711c indep*/
                    if mov-insu.cd-tipo-cob    <> 6
                    then . 
                    else next. 
                end. 
            end.
        end.

        define variable lg-erro-copart as logical no-undo.
        define variable dc-valor-copart as decimal no-undo.
        
        run SimulaCoparticipacao(output lg-erro-copart,
                                 output dc-valor-copart).
                    
        if lg-erro-copart then next.
        
                             
                    
        create XML_ALERTA.
        assign in-conta                             = in-conta + 1
               XML_ALERTA.CHAVE_SISTEMA             = "COP" + RegistroPrimary(buffer moviproc:handle)
               XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
               XML_ALERTA.TITULO                    = CH_MENSAGEM_COPART_NAO_FATURADA
               XML_ALERTA.DESCRICAO                 = substitute ("Documento: &1/&2/&3/&4/&5/&6, Procedimento: &7, sequencia &8",
                                                                  moviproc.cd-unidade,
                                                                  moviproc.cd-unidade-prestadora,
                                                                  moviproc.cd-transacao,
                                                                  moviproc.nr-serie-doc-original,
                                                                  moviproc.nr-doc-original,
                                                                  moviproc.nr-doc-sistema,
                                                                  substitute ("&1&2&3&4", 
                                                                              string (moviproc.cd-esp-amb, '99'),
                                                                              string (moviproc.cd-grupo-proc-amb, '99'),
                                                                              string (moviproc.cd-procedimento, '999'),
                                                                              string (moviproc.dv-procedimento, '9')),
                                                                  moviproc.nr-seq-digitacao)
               XML_ALERTA.ANO                       = in-ano
               XML_ALERTA.MES                       = in-mes         
               XML_ALERTA.CHAVE_SISTEMA_BENEF       = RegistroPrimary (buffer usuario:handle)
               XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
               XML_ALERTA.CODIGO_CART_BENEF         = string (moviproc.cd-carteira-usuario, '9999999999999')
               XML_ALERTA.CODIGO_UNIDADE_BENEF      = moviproc.cd-unidade-carteira
               XML_ALERTA.VALOR                     = dc-valor-copart.
               
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'C¢digo Glosa'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-cod-glo)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 

        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma Pagamento'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-forma-pagto)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
    
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma Cobranáa'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-forma-pagto-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
               
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Tipo Cob'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-tipo-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA).                         
               
        if in-conta = 100
        then do:
            EnviarDados (dataset XML_ALERTAS:handle).
            dataset XML_ALERTAS:empty-dataset ().
            in-conta = 0.            
        end.                                   
              
    end.
    
    
end procedure.


procedure ProcessaMesAno: 
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input        parameter in-mes                as   integer        no-undo.
    define input        parameter in-ano                as   integer        no-undo.
    
    find first paramecp no-lock.

    run ProcessaNotaServico (input  in-mes,
                             input  in-ano).
    
    run ProcessaNaoLiberados (input  in-mes,
                              input  in-ano).

    EnviarDados (dataset XML_ALERTAS:handle).
    dataset XML_ALERTAS:empty-dataset ().
    

end procedure.

procedure ProcessaNaoLiberados:
    define input  parameter in-mes              as   integer    no-undo.
    define input  parameter in-ano              as   integer    no-undo.
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable dt-inicio                   as   date       no-undo.
    define variable dt-fim                      as   date       no-undo.
    
    assign dt-inicio    = date (in-mes, 1, in-ano)
           dt-fim       = UltimoDiaMes (in-ano, in-mes).

    log-manager:write-message (substitute ('periodo: entre &1 e &2', dt-inicio, dt-fim ),'DEBUG').           
           
    for each perimovi no-lock:

        if perimovi.dt-fim-per      < dt-inicio then next.
        if perimovi.dt-inicio-per   > dt-fim    then next.

        log-manager:write-message (substitute ('lendo period &1/&2, inicio em &3 e fim &4',
                                               perimovi.dt-anoref,
                                               perimovi.nr-perref,
                                               perimovi.dt-inicio-per,
                                               perimovi.dt-fim-per ),'DEBUG').

        run LeProcedimentos (input  perimovi.dt-anoref, 
                             input  perimovi.nr-perref,
                             input  in-ano,
                             input  in-mes).
                             
/*        run LeInsumos (input  perimovi.dt-anoref,*/
/*                       input  perimovi.nr-perref,*/
/*                       input  in-ano,            */
/*                       input  in-mes).           */
                                                                                                          
    end.             
end procedure.

procedure ProcessaNotaServico:
    define input  parameter in-mes              as   integer    no-undo.
    define input  parameter in-ano              as   integer    no-undo.

    define buffer   buf-contrat-orig            for  contrat.
    
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    for each notaserv no-lock
       where notaserv.cd-modalidade     > 0
         and notaserv.nr-ter-adesao     > 0
         and notaserv.aa-referencia     = in-ano
         and notaserv.mm-referencia     = in-mes
         and (   notaserv.in-tipo-nota  = 2
              or notaserv.in-tipo-nota  = 7),
       first propost no-lock
       where propost.cd-modalidade      = notaserv.cd-modalidade
         and propost.nr-ter-adesao      = notaserv.nr-ter-adesao,
       first ter-ade no-lock
       where ter-ade.cd-modalidade      = propost.cd-modalidade
         and ter-ade.nr-ter-adesao      = propost.nr-ter-adesao:
             
        if ter-ade.in-contratante-participacao   = 0
        then find first contrat no-lock
                  where contrat.cd-contratante  = propost.cd-contratante.
        else find first contrat no-lock
                  where contrat.cd-contratante  = propost.cd-contrat-origem.                   
        
        if notaserv.nr-fatura   = 0
        then do:
            
            create XML_ALERTA.              
            assign XML_ALERTA.CHAVE_SISTEMA             = "CP" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_NOTASERV_SEM_FATURA
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, per°odo: &2/&3, espÇcie &4, seq: &5, emiss∆o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total .            
            next.                 
        end.
        
        find first fatura no-lock
             where fatura.cd-contratante   = contrat.cd-contratante
               and fatura.nr-fatura        = notaserv.nr-fatura
                   no-error.
                   
        if not available fatura                             
        then do:

            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = "CP" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_NOTASERV_VINCULADO_FATURA_INEXISTENTE
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, per°odo: &2/&3, espÇcie &4, seq: &5, emiss∆o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total . 
            next.
        end.

        if fatura.cd-sit-fatu   = 10
        or fatura.cd-sit-fatu   = 20
        or fatura.nr-titulo-acr = ''
        then do:
            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = "CP" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_FATURA_NAO_INTEGRADA_FINANCEIRO
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, per°odo: &2/&3, espÇcie &4, seq: &5, emiss∆o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total . 

            next. 
        end.         
        
  
        find first tit_acr no-lock  
             where tit_acr.cod_estab       = fatura.cod-estabel
               and tit_acr.cod_espec_docto = fatura.cd-especie
               and tit_acr.cod_ser_docto   = substring (fatura.serie-nf, 1, 3)
               and tit_acr.cod_tit_acr     = fatura.nr-titulo-acr
               and (   string (int(tit_acr.cod_parcela), '99')  =  string (fatura.parcela, "99")
                    or (    fatura.parcela   = 0
                        and tit_acr.cod_parcela = ''
                        ))
                   no-error.    
         
        if not available tit_acr
        then do:
            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = "CP" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_FATURA_VINCULADO_TITULO_INEXISTENTE
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, per°odo: &2/&3, espÇcie &4, seq: &5, emiss∆o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total . 

            next. 
        end.
    end.                                  

    EnviarDados (dataset XML_ALERTAS:handle).
    dataset XML_ALERTAS:empty-dataset ().

end procedure.

