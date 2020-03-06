
/*------------------------------------------------------------------------
    File        : cpc-rtapi058.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon Jun 05 10:33:14 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */



/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
{rtp/rtapi058.i}
{hdp/hdttable.i}

{rcp/rcapi020.i "shared" } /* -------------------------- DOCUMENTO DO RC --- */
{rcp/rcapi021.i "shared" } /* --------------- PROCEDIMENTOS DO DOCUMENTO --- */
{rcp/rcapi022.i "shared" } /* --------------------- INSUMOS DO DOCUMENTO --- */


message "cpc rtpia058 CASALI" view-as alert-box.


find first tmp-rtapi058-entrada no-lock no-error.



if not available tmp-rtapi058-entrada 
then do:
    message "temp entrada nao disponivel"
    view-as alert-box.
    return.
end.


create tmp-cpc-rtapi058-saida.
assign tmp-cpc-rtapi058-saida.lg-undo-retry             = no
       tmp-cpc-rtapi058-saida.lg-restringe-movimento    = no.       
       
       
find first paramecp no-lock.       

for each tmp-moviproc:
    
    if  tmp-moviproc.cd-pacote  = 41301323
    and tmp-moviproc.cd-unidade-prestador   = paramecp.cd-unimed
    and (   tmp-moviproc.cd-prestador       = 82179
         or tmp-moviproc.cd-prestador       = 93311
         or tmp-moviproc.cd-prestador       = 142649)   
    then do:
        assign tmp-cpc-rtapi058-saida.lg-restringe-movimento    = yes
               tmp-cpc-rtapi058-saida.cd-classe-erro            = 24
               tmp-cpc-rtapi058-saida.cd-mensiste               = 0
               tmp-cpc-rtapi058-saida.ds-mensagem-relatorio     = "TESTE CASALI"
               tmp-cpc-rtapi058-saida.ds-mensagem-livre         = "TESTE LIVRE CASALI". 
        return.
    end.
end.                
       

