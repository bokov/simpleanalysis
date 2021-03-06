#' ---
#' title: "Example Analysis"
#' css: "production.css"
#' output:
#'   html_document:
#'     toc: true
#'     toc_float: true
#'     toc_depth: 4
#' ---
#'
#' ### Settings
#'
#' In the below two lines are the minimum script-level settings you need.
#' The `.projpackages` object has the names of the packages you need installed
#' if necessary and then loaded for this scriport. The `.deps` object contains
#' other scriports on which this one _directly_ depends (you don't need to worry
#' about the indirect ones-- each scriport manages its own dependencies for
#' packages and scriports). The recommended value to start with is the one shown
#' here. You can add more if the need arises later. For more information, please
#' see the [overview](overview.html) scriport.
.projpackages <- c('GGally','tableone','pander','dplyr','ggplot2');
.deps <- c( 'dictionary.R' );
#+ load_deps, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
# do not edit the next two lines
.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE));
#' Set some formatting options for this document
panderOptions('table.alignment.default','right');
panderOptions('table.alignment.rownames','right');
panderOptions('table.split.table',Inf);
panderOptions('p.wrap','');
panderOptions('p.copula',', and ');

.currentscript <- current_scriptname('example_analysis.R');
if(!exists('dat01')) dat01 <- get(names(inputdata)[1]);
#'
#'
#' ### Choosing predictor and response variables
#'
#' The values below both represent birth weight on the same babies, but
#' `binary_outcome` is whether or not that birth weight is < 2.5kg and
#' `numeric_outcome` is the actual birth weight.
binary_outcome <- 'low';
binary_outcome;
numeric_outcome <- 'bwt';
numeric_outcome;
#'
predictorvars <- c('age','lwt','race','smoke','ptl','ht','ui','ftv');
predictorvars;

mainvars <- c(predictorvars,binary_outcome,numeric_outcome);
mainvars;
#'
#' ### Data dictionary
#'
#' Here are some useful characteristics of the variables in `dat01`
#'
pander(attr(dat01,'tblinfo') %>% select(-c('nn','md5')));

#'
#' ### Plot the data
#'
#' #### Explore pairwise relationships
#'
#' A plot of all pairwise relationships between the variables of interest.
#+ ggpairs_plot, message=FALSE, warning=FALSE, cache=TRUE

# select just the columns in 'mainvars' (otherwise the plot will take forever)
# and turn the ones tagged as 'ordinal' into factors
dat01[,mainvars] %>% mutate_at(.,v(c_ordinal,.),factor) %>%
  # now make a scatterplot matrix, using the first 'binary_outcome' to assign
  # color
  ggpairs(.,aes_string(color=binary_outcome[1]));
#'
#' #### Exploring group differences.
#'
#' The `r sprintf("\x60%s\x60",binary_outcome[1])`
#' variable is again used to stratify the groups to create a cohort table that
#' can, among other things, help identify potential confounders and unexpected
#' explanatory variables.
#'
pander(print(CreateTableOne(vars = mainvars, strata = binary_outcome[1]
                            ,data=dat01, includeNA=TRUE, test=FALSE)
             , printToggle=FALSE)
       ,caption='Cohort Characterization');
#'
#' ### Fit the statistical models
#'
#' Formulas for the numeric outcome models.
#+ numfrm, results='asis'
num_formulas <- c();
for(yy in numeric_outcome) for(xx in predictorvars){
  num_formulas <- c(num_formulas,sprintf('%s ~ %s',yy,xx))};
pander(cbind(num_formulas),justify='l');

#' Linear regression models fitted to the above formulas.
num_models <- sapply(num_formulas,function(xx) lm(xx,dat01) %>% update(.~.)
                     ,simplify=FALSE);

#'
#' #### Results of univariate numerical models (linear regression)
#+ pandernum,results='asis'
for(xx in num_models) {cat('***','\n'); cat(pander(xx)); cat('***','\n');};
#'
#'
#' Formulas for the binary outcome models
#+ binfrm, results='asis'
bin_formulas <- c();
for(yy in binary_outcome) for(xx in predictorvars){
  bin_formulas <- c(bin_formulas,sprintf('%s ~ %s',yy,xx))};
pander(cbind(bin_formulas),justify='l');
#' Logistic regression models fitted to the above formulas.
bin_models <- sapply(bin_formulas,function(xx){
  glm(xx,dat01,family='binomial') %>% update(.~.)},simplify=FALSE);
#' #### Results of univariate binary models (logistic regression)
#+ panderbin,results='asis'
for(xx in bin_models) {cat('***','\n'); cat(pander(xx)); cat('***','\n');};
#'
#'
#' ### Save results
#'
#'
#' Now the results are saved and available for use by other scriports if you
#' place `r sprintf("\x60'%s'\x60",.currentscript)` among the values in their
#' `.deps` variables.
save(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
#+ echo=FALSE, results='hide'

c()