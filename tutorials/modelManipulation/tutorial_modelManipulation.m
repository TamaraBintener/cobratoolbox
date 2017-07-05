%% Model manipulation
% *Author(s): Vanja Vlasov, Systems Biochemistry Group, LCSB, University of 
% Luxembourg,*
% 
% *Thomas Pfau,  Systems Biology Group, LSRU, University of Luxembourg.*
% 
% *Reviewer(s): Ines Thiele, Systems Biochemistry Group, LCSB, University 
% of Luxembourg.*
%% INTRODUCTION
% In this tutorial, we will do a manipulation with the simple model of the first 
% few reactions of the glycolysis metabolic pathway as created in the "Model Creation" 
% tutorial. 
% 
% Glycolysis is the metabolic pathway that occurs in most organisms in the 
% cytosol of the cell. First, we will use the beginning of that pathway to create 
% a simple constraint-based metabolic network (Figure 1).
% 
% 
% 
%                                                                    Figure 
% 1: A small metabolic network consisting of the seven reactions in the glycolysis 
% pathway. 
% 
% At the beginning of the reconstruction, the initial step is to assess an 
% integrity of the draft reconstruction. Furthermore, an accuracy evaluation is 
% needed: check necessity of each reaction and metabolite,  the accuracy of the 
% stoichiometry and direction and reversibility of the reactions.
% 
% After creating or loading the model, the model can be modified to simulate 
% different conditions, such as:
% 
% * Creating, adding and handling reactions;
% * Adding Exchange, Sink and Demand reactions;
% * Altering reaction bounds;
% * Altering Reactions;
% * Remove reactions and metabolites;
% * Search for duplicates and comparison of two models;
% * Changing the model objective;
% * Changing the direction of reaction(s);
% * Create gene-reaction-associations ('GPRs');
%% EQUIPMENT SETUP
% Start CobraToolbox

initCobraToolbox;
%% PROCEDURE
%% Generate a network
% A constraint-based metabolic model contains the stoichiometric matrix with 
% reactions and metabolites [1].
% 
% $$S$ is a stoichiometric representation of metabolic networks corresponding 
% to the reactions in the biochemical pathway. In each column of the $$S$ is a 
% biochemical reaction ($$n$) and in each row is a precise metabolite ($$m$). 
% There is a stoichiometric coefficient of zero, which means that metabolite does 
% not participate in that distinct reaction. The coefficient also can be positive 
% when the appropriate metabolite is produced, or negative  for every metabolite 
% depleted [1].

ReactionFormulas = {'glc_D[e]  -> glc_D[c]',...
    'glc_D[c] + atp[c]  -> h[c] + adp[c] + g6p[c]',...
    'g6p[c]  <=> f6p[c]',...
    'atp[c] + f6p[c]  -> h[c] + adp[c] + fdp[c]',...
    'fdp[c] + h2o[c]  -> f6p[c] + pi[c]',...
    'fdp[c]  -> g3p[c] + dhap[c]',...
    'dhap[c]  -> g3p[c]'};
ReactionNames = {'GLCt1r', 'HEX1', 'PGI', 'PFK', 'FBP', 'FBA', 'TPI'};
lowerbounds = [-20, 0, -20, 0, 0, -20, -20];
upperbounds = [20, 20, 20, 20, 20, 20, 20];
model = createModel(ReactionNames, ReactionNames, ReactionFormulas,...
                   'lowerBoundList', lowerbounds, 'upperBoundList', upperbounds);
%% 
% We can now have a look at the different model fields created. The stoichiometry 
% is stored in the $$S$ field of the model, which was described above. Since this 
% is commonly a sparse matrix (i.e. it does contain a lot of zeros) to display 
% it, it is useful to use the full representation:

full(model.S)
%% 
% Some descriptive fields always present are |model.mets| and |model.rxns| 
% which represent the metabolites and the reactions respectively. 

model.mets
model.rxns
%% 
% Fields in the COBRA model are commonly column vectors, which can be an 
% important detail when writing functions manipulating these fields.
% 
% There are a few more fields present in each COBRA model:
% 
% |model.lb|, indicating the lower bounds of each reaction, and |model.ub| 
% indicating the upper bound of a reaction.

% this displays an array with reaction names and flux bounds.
[{'Reaction ID', 'Lower Bound', 'Upper Bound'};...   
 model.rxns, num2cell(model.lb), num2cell(model.ub)]
% This is a convenience function which does pretty much the same as the line above.
printFluxBounds(model);
%% 
% Before we start to modify the model, it might be useful to store some 
% of the current properties of the model

mets_length = length(model.mets);
rxns_length = length(model.rxns);
%% Creating, adding and handling reactions
% If we want to add a reaction to the model or modify an existing reaction we 
% are using function |addReaction|. 
% 
% We will add some more reactions from glycolysis.
% 
% * The formula approach

model = addReaction(model, 'GAPDH',...
       'reactionFormula', 'g3p[c] + nad[c] + 2 pi[c] -> nadh[c] + h[c] + 13bpg[c]');
model = addReaction(model, 'PGK',...
       'reactionFormula', '13bpg[c] + adp[c] -> atp[c] + 3pg[c]');
model = addReaction(model, 'PGM', 'reactionFormula', '3pg[c] <=> 2pg[c]' );
%% 
% Display of stoichiometric matrix after adding reactions. Note the enlarge 
% link when you move your mouse over the output to display the full matrix:

full(model.S) 
% one extra column is added(for added reaction) and 5 new 
% rows(for nadh, nad, 13bpg, 2pg and 3pg metabolites)
%% 
% If you want to search reactions sequence in the model and change the order 
% of the selected reaction, use the following functions.

rxnID = findRxnIDs(model, model.rxns);
model = moveRxn(model, 8, 1);
%% 
% While the latter does not modify the structure as such it can help in 
% keeping a model tidy.
% 
% * The list approach
% 
%  The |addReaction| function has ability to recognize duplicate reactions 
% when an order of metabolites and an abbreviation of the reaction are different.

model = addReaction(model, 'GAPDH2',...
    'metaboliteList', {'g3p[c]', 'nad[c]', 'pi[c]', '13bpg[c]', 'nadh[c]', 'h[c]' },...
    'stoichCoeffList', [-1; -1; -2; 1; 1; 1], 'reversible', false);
%% 
% Since the second call should not have added anything we will check if 
% the number of the reaction increased by the three reactions we added (and not 
% by the one duplicated) and the number of metabolites was incremented by five 
% (13bpg, nad, nadh, 23bpg and 2pg).

assert(length(model.rxns) == rxns_length + 3);
assert(length(model.mets) == mets_length + 5);
%% Adding Exchange, Sink and Demand reactions
% The specific type of reactions in the constraint-based models are reactions 
% that are using and recycling accumulated metabolites or producing required metabolites 
% in the model.
% 
% # _Exchange reactions _-  Reactions added to the model to move metabolites 
% across the created _in silico _compartments. Those compartments represent intra- 
% and intercellular membranes.
% # _Sink reactions_ - The metabolites, produced in reactions that are outside 
% of an ambit of the system or in unknown reactions, are supplied to the network 
% with reversible sink reactions.
% # _Demand reactions_ - Irreversible reactions added to the model to consume 
% metabolites that are deposited in the system.
% 
% There are two ways to implement that kind of reactions:
% 
% # *Use |addReaction| with the documented function call:*

model = addReaction(model, 'EX_glc_D[e]', 'metaboliteList', {'glc_D[e]'} ,...
                    'stoichCoeffList', [-1]);
%% 
%     In the bigger networks we can find our exchange reactions with the 
% following functions:

% determines whether a reaction is a general exchange reaction and
% whether its an uptake.
[selExc, selUpt] = findExcRxns(model, 0, 1)
%% 
%          *2.  Use a utility function to create a particular reaction type: 
% |addExchangeRxn|, |addSinkReactions|, |addDemandReaction|.*

model = addExchangeRxn(model, {'glc_D[e]', 'glc_D[c]'})
%% 
%    

model = addSinkReactions(model, {'13bpg[c]', 'nad[c]'})
%% 
% 

 model = addDemandReaction(model, {'dhap[c]', 'g3p[c]'})
%% Setting ratio between the reactions and changing reactions boundary
% It is important to emphasise that previous knowledge base information should 
% be taken into account. Most of them could disrupt future analysis of the model. 
% 
% For instance, if it is familiar that flux through one reaction is _X_ times 
% the flux through another reaction, it is recommended to specify that in your 
% model. 
% 
%  E.g. $<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mrow><mn>1</mn><mtext> 
% </mtext><mi mathvariant="italic">v</mi><mtext> </mtext><mi mathvariant="normal">EX</mi><mo 
% stretchy="false">_</mo><mi mathvariant="normal">glc</mi><mo stretchy="false">_</mo><mi>D</mi><mo>[</mo><mi>c</mi><mo>]</mo><mo 
% stretchy="false">=</mo><mn>2</mn><mtext> </mtext><mi mathvariant="italic">v</mi><mtext> 
% </mtext><mi mathvariant="normal">EX</mi><mo stretchy="false">_</mo><mi mathvariant="normal">glc</mi><mo 
% stretchy="false">_</mo><mi>D</mi><mo>[</mo><mi mathvariant="italic">e</mi><mo>]</mo></mrow></math>$

model = addRatioReaction (model, {'EX_glc_D[c]', 'EX_glc_D[e]'}, [1; 2]);
%% *Altering Reaction bounds*
% In order to respect the transport and exchange potential of a particular metabolite, 
% or to resemble the different conditions in the model, we frequently need to 
% set appropriate limits of the reactions.

model = changeRxnBounds(model, 'EX_glc_D[e]', -18.5, 'l');
%% Modifying Reactions
% The |addReaction| function also is a good choice when modifying reactions. 
% By supplying a new stoichiometry, the old will be overwritten. For example, 
% further up, we added a wrong stoichiometry for the GAP-Dehydrogenase with a 
% phosphate coefficient of 2. (easily visible by printing the reaction)

printRxnFormula(model, 'rxnAbbrList', 'GAPDH');
%% 
% We can correct this by simply calling |addReaction| again with the corrected 
% stoichiometry. In essence, parts which are not provided are taken from the old 
% reaction, and only the new ones overwrite the existing data.

model = addReaction(model, 'GAPDH',...
    'metaboliteList', {'g3p[c]', 'nad[c]', 'pi[c]', '13bpg[c]', 'nadh[c]','h[c]' },...
    'stoichCoeffList', [-1; -1; -1; 1; 1; 1]);
%% 
% We might also want to add a gene rule to the reaction. This can either 
% be done using 

model = changeGeneAssociation(model, 'GAPDH', 'G1 and G2');
printRxnFormula(model, 'rxnAbbrList', {'GAPDH'}, 'gprFlag', true);
%% 
% The other option to achieve this is to use |addReaction| and the |geneRule| 
% parameter. 

model = addReaction(model, 'PGK', 'geneRule', 'G2 or G3', 'printLevel', 0);
printRxnFormula(model, 'gprFlag', true);
%% Remove reactions and metabolites
% In order to detach reactions from the model, the following function has been 
% used:

 model = removeRxns(model, {'EX_glc_D[c]', 'EX_glc_D[e]', 'sink_13bpg[c]', ...
                             'sink_nad[c]', 'DM_dhap[c]', 'DM_g3p[c]'});

 assert(rxns_length + 3 == length(model.rxns)); 
 % The reaction length has been reevaluated 
%% 
% Remove metabolites

  model = removeMetabolites(model, {'3pg[c]', '2pg[c]'}, false);
%% 
% For instance, in the previous code, many metabolites from '|GAPDH|' were 
% deleted, but the reaction is still present in the model (since there are more 
% metabolites left). The false indicates, that empty reactions should not be removed.
% 
% To delete metabolites and reactions with zero rows and columns,the following 
% function can be used:

  model = removeTrivialStoichiometry(model)
  model = removeRxns(model,{'GAPDH', 'PGK'});
%% Search for duplicates and comparison of two models
% Since genome-scale metabolic models are expanding every day [2], the need 
% for comparison of them is also spreading. 
% 
% The elementary functions for the model manipulation, besides main actions, 
% simultaneously perform the structural analysis and comparison (e.g. |addReaction|). 
% Likewise, there are additional functions that are only dealing with analyzing 
% similarities and differences within and between the models.
% 
% * Checking for reaction duplicates by reaction abbreviation, by using method 
% '|S|' that will not detect reverse reactions and method '|FR|' that will neglect 
% reactions direction:

[model, removedRxn, rxnRelationship] = checkDuplicateRxn(model, 'S', 1, 1);
%% 
% Adding duplicate reaction to the model:

model = addReaction(model, 'GLCt1r_duplicate_reverse',...
                    'metaboliteList', {'glc_D[e]', 'glc_D[c]'},...
                    'stoichCoeffList', [1 -1], 'lowerBound', 0, ...
                    'upperBound', 20, 'checkDuplicate', 0);
fprintf('>> Detecting duplicates using S method\n');
method = 'S'; 
% will not be removed as does not detect a reverse reaction
[model,removedRxn, rxnRelationship] = checkDuplicateRxn(model, method, 1, 1);
assert(rxns_length + 1 == length(model.rxns)); 
% The reaction length has been reevaluated

fprintf('>> Detecting duplicates with using FR method\n');
method = 'FR';
% will be removed as detects a reverse reaction
[model, removedRxn, rxnRelationship] = checkDuplicateRxn(model, method, 1, 1);
assert(rxns_length == length(model.rxns));
%% 
% * Function| checkCobraModelUnique| marks the reactions and metabolites that 
% are not unique in the model.

model = checkCobraModelUnique(model, false)
%% Changing the model's objective
% Simulating different conditions in the model is often necessary for a favor 
% of performing calculations that investigate a specific objective. One of the 
% elementary objectives is optimal growth [3]. The model can be modified to get 
% different conditions with changing the model objective:

modelNew = changeObjective(model, 'GLCt1r', 0.5);

% multiple reactions, default coefficient (1)
modelNew = changeObjective(model, {'PGI'; 'PFK'; 'FBP'});

%% The direction of reactions 
% For some purposes, it is important to only have irreversible reactions in 
% a model, i.e. only allowing positive flux in all reactions. This can be important 
% if e.g. absolute flux values are of interest and negative flux would reduce 
% an objective while it should actually increase it. The COBRA Toolbox offers 
% functionality to change a model to an irreversible format, by splitting all 
% reversible reactions and adjusting the respective lower and upper bounds, such 
% that the model capacities stay the same. 
% 
% Let us see, how the glycolysis model currently looks:

printRxnFormula(model);
%% 
% To convert a model to an irreversible model use the following command:

[modelIrrev, matchRev, rev2irrev, irrev2rev] = convertToIrreversible(model);
%% 
% Compare the irreversible model with the original model:

printRxnFormula(modelIrrev);
%% 
% You will notice, that there are more reactions in this model and that 
% all reactions which have a lower bound < 0 are split in two. 
% 
% There is also a function to convert an irreversible model to a reversible 
% model:

modelRev = convertToReversible(modelIrrev);
%% 
% If we now compare the reactions of this model with those from the original 
% model, they should look the same.

printRxnFormula(modelRev);
%% Create gene-reaction-associations ('GPRs') from scratch.

model.genes = [];
model.rxnGeneMat = [];
modelgrRule = model.grRules;
for i = 1 : length(modelgrRule)
    if ~isempty(modelgrRule{i})
        model = changeGeneAssociation(model,model.rxns{i},modelgrRule{i});
    end
end
%% 
% Check that there are no empy columns left.

find(sum(model.rxnGeneMat)==0)
%% Replace an old GPR with a new one. 
% Here, we will search for all instances of the old GPR and replace it by the 
% new one.
% 
% Define the old and the new one. 

GPRsReplace={'(126.1) or (137872.1) '	'126.1 or 137872.1'};
GP = (model.grRules);
a = 1;
for  i = 1 : size(GPRsReplace,1)
    tmp2=[];
    for j = 1 :length(GP)
        tmp2 = strmatch(GPRsReplace{i,1},GP{j});
        % replace old GPR by new
        model.grRules{j} = GPRsReplace{i,2};
    end
end
%% 
% Remove issues with hyphens in the GPR definitions.

for i = 1 : length(model.grRules)
    model.grRules{i} = strrep(model.grRules{i}, '''', '');
end
%% 
% Remove spaces from reaction abbreviations.

for i = 1 : length(model.rxns)
    model.rxns{i} = strrep(model.rxns{i}, ' ', '');
end
%% 
% Remove unneccessary brackets from the GPR associations. 

for i = 1 : length(model.grRules)
    model.grRules{i} = strrep(model.grRules{i}, '''', '');
    % remove unnecessary brackets
    if length(strfind(model.grRules{i},'and')) == 0 % no AND in gprs
        model.grRules{i} = strrep(model.grRules{i}, '(', '');
        model.grRules{i} = strrep(model.grRules{i}, ')', '');
        
    elseif length(strfind(model.grRules{i},'or')) == 0 % no OR in gprs
        model.grRules{i} = strrep(model.grRules{i}, '(', '');
        model.grRules{i} = strrep(model.grRules{i}, ')', '');
    elseif length(strfind(model.grRules{i},'(')) == 1 && length(strfind...
            (model.grRules{i},'or')) == 0 && length(strfind...
            (model.grRules{i},'and')) == 0
        model.grRules{i} = strrep(model.grRules{i}, '(', '');
        model.grRules{i} = strrep(model.grRules{i}, ')', '');
    end
end
%% REFERENCES
% [1] Orth, J. D., Thiele I., and Palsson, B. Ø. (2010). What is flux balance 
% analysis? _Nat. Biotechnol., 28_(3), 245–248.
% 
% [2] Feist, A. M., Palsson, B. (2008). The growing scope of applications 
% of genome-scale metabolic reconstructions: the case of _E. coli_. _Nature Biotechnology, 
% 26_(6), 659–667.
% 
% [3] Feist, A. M., Palsson, B. O. (2010). The Biomass Objective Function. 
% _Current Opinion in Microbiology, 13_(3), 344–349.