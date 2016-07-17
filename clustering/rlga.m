function out = rlga(X,k,alpha,varargin)

% VERIFICARE LINEE 134 -- 136 ALPHA NON TORNA PER NIENTE !!!!!!!!   

%rlga performs robust linear grouping analysis
%
%
%<a href="matlab: docsearchFS('rlga')">Link to the help function</a>
%
%  Required input arguments:
%
%       X   : input data matrix. Matrix. Input data as matrix of size
%            n-by-p
%       k   : number of clusters. Scalar. Scalar which specifies the number
%             of clusters.
%    alpha  : a numeric value between 0 and 0.5. Scalar. For the robust estimate of
%             LGA, specifying the percentage of points to be trimmed.
%             alpha must be a number in the interval [0 0.5]   
%
%  Optional input arguments:
%
%
%     biter : an integer for the number of different starting hyperplanes
%               to try. Integer.
%               Example - 'biter',1 
%               Data Types - double
%     niter : an integer for the number of iterations to attempt for convergence. Integer.
%               Example - 'niter',1 
%               Data Types - double
%   showall :  If true then display all the outcomes, not just the best
%               one. Logical.
%               Example - 'showall','true' 
%               Data Types - char 
%    stand  : If true standardize the X matrix with the standard
%             deviation before fitting. Logical.
%               Example - 'stand','true' 
%               Data Types - char 
%    silent : Text output. Logical. If true, produces no text output during processing. 
%             The default value is false
%               Example - 'silent','true' 
%               Data Types - char                  
%    plots  : plot on the screen. Scalar. If plots=1 a plot is showed on the screen with the
%             final allocation (and if size(X,2)==2 with the lines
%             associated to the groups). 
%               Example - 'plots',1 
%               Data Types - double
%
%  Output:
%
%         out:   structure which contains the following fields
%
%            out.cluster  = vector containing the cluster memberships.
%              out.ROSS   = the Residual Orthogonal Sum of Squares for the solution.
%           out.converged = logical. True if at least one solution has converged.
%          out.nconverg   = the number of converged solutions (out of biter starts).
%          out.hpcoeff     =  best hyerplane
%           out.x	      = the (scaled if selected) dataset.
%          out.scaled     = logical. Is the data set scaled?
%          out.k          = the number of clusters to be found.
%           out.biter     = the biter setting used.
%           out.niter	  = the niter setting used.
%             out.class = 'rlga'.
%
% See also: lga.m
%
% References:
%
% Garc?a-Escudero, L. A., Gordaliza, A., San Mart?n, R., Van Aelst, S. and
% Zamar, R. (2009), Robust linear clustering. Journal of the Royal
% Statistical Society: Series B (Statistical Methodology), 71: 301?318.
% doi: 10.1111/j.1467-9868.2008.00682.x
%
%
% Copyright 2008-2016.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('rlga')">Link to the help page for this function</a>
% Last modified 14-06-2016


%
% Examples:
%
%{
    % rlga with all default options.
    X=load('X.txt');
    out=rlga(X,3,0.5);
%}
%{
    % rlga with all niter = 1000 and biter = 3000.
    X=load('X.txt');
    out=rlga(X,4,0.5,'niter',1000,'biter',3000);
%}
%

%% Beginning of code


[n,d]=size(X);

n1= ceil(n/k);
p=0.95;
biterdef=ceil(log(1-p)/log(1-nchoosekFS(n1,d)^k/nchoosekFS(n1*k,k*d)));

niterdef=10;

options=struct('biter',biterdef,'niter',niterdef,'showall',false,...
    'stand',true,'silent',false,'plots',1);

% Write in structure 'options' the options chosen by the user
for i=1:2:length(varargin)
    options.(varargin{i})=varargin{i+1};
end

% Default value of p

UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    
    
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
            error('FSDA:rlga:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    
    % Check if all the specified optional arguments were present
    % in structure options
    inpchk=isfield(options,UserOptions);
    WrongOptions=UserOptions(inpchk==0);
    if ~isempty(WrongOptions)
        disp(strcat('Non existent user option found->', char(WrongOptions{:})))
        error('FSDA:rlga:NonExistInputOpt','In total %d non-existent user options found.', length(WrongOptions));
    end
end

if alpha>0.5
     error('FSDA:rlga:WrongAlpha','Error:: alpha must be in [0.5, 1]');
end

biter=options.biter;
niter=options.niter;
silent=options.silent;

if ~silent
    disp(['RLGA Algorithm k =', num2str(k), ' biter =', num2str(biter), ...
        ' niter =', num2str(niter), ''])
end

stand=options.stand;

if stand
    sigma = std(X);
    X = bsxfun(@rdivide, X, sigma);
end

% hpcoef is a a 3D array of size
% number of cluster-times-number of variables+1-times-biter
% each row is a hyperplane
hpcoef=zeros(k,d+1,biter);

for j=1:biter
    % Choose starting clusters
    clindex=reshape(randsample(1:n,k*d),k,d);
%      clindex(1,:)=[191 185];
%      clindex(2,:)=[51, 27];
%      clindex(3,:)=[8, 35];
    
    for i=1:k
        hpcoef(i,:,j)=lgaorthreg(X(clindex(i,:),:));
    end
end


% nnode = an integer of many CPUS to use for parallel processing. Defaults
% to NULL i.e. no parallel processing.
% nnode=options.nnode;
% if isempty(nnode)
% not parallelrows 1:n contain the information about group assignment
% row n+1 contains information about convergence (1) or non convergence (0)
% row n+2 contains information about ROSS
outputs=zeros(n+2,biter);
for j=1:biter
    outputs(:,j)=rlgaiterate(hpcoef(:,:,j),X, k, d, n, niter,alpha);
end
% else
%     % parallel
%
% end


% Find the number of converged results
nconverg = sum(outputs(n+1,:));
if nconverg == 0
    warning('FSDA:rlga:NoConvergence','rlga failed to converge for any iteration')
end

showall=options.showall;

if ~showall
    % remove any columns of matrix outputs which contains NAs
    outputs = outputs(:, sum(isnan(outputs))==0);
    
    
    if (nconverg ~= 0)
        outputs = outputs(:,outputs(n+1,:)==1);
    end
    
    % using the instruction below we take the column of outputs which is
    % associated to the first minimum
    [~,minoutindcol]=min(outputs(n+2,:));
    outputs=outputs(:,minoutindcol);
    
    
    % In the instruction below we check whether there is more than one
    % minimum
    %{
    minout=min(outputs(n+2,:));
    minoutindcol=outputs(n+2,:)==minout;
    outputs = outputs(:,minoutindcol);
    
    if size(outputs,2) > 1
        outputs = lgaCheckUnique(outputs);
    end
    %}
    
end

if (~silent)
    disp('Finished.')
end

if showall
    disp('Returning all outputs')
    ROSS = outputs(n+2,:);
    hp =nan;
else
    
    
    % Fit the best hyerplane(s) with ROSS
    hp =nan(k,d+1);
    for i=1:k
        hp(i,:)=lgaorthreg(X(outputs(1:n)== i,:));
    end
    
    ROSS=rlgacalculateROSS(hp, X, n, d, outputs(1:n));
    
end

out.cluster=outputs(1:n,:);
out.ROSS=ROSS;
out.converged=outputs(n+1,:);
out.nconverg=nconverg;
out.X=X;
out.hpcoeff=hp;


out.biter=biter;
out.niter=niter;
out.scaled=stand;
out.k=k;
out.class='rlga';


plots=options.plots;

if plots
    if d==2
        
        % spmplot(X,cluster)
        gscatter(X(:,1),X(:,2),out.cluster)
        v=axis';
        hold('on')
        for i=1:k
            a= hp(i, 3)/hp(i, 2);
            b= -hp(i, 1)/hp(i, 2);
            plot(v(1:2),a+b*v(1:2))
        end
    else
        spmplot(X,out.cluster)
        
    end
    
end


    function yorthreg=lgaorthreg(X)
        % Perform orthogonal regression.
        mu = mean(X);
        y = bsxfun(@minus,X, mu);
        
        %y <- scale(x, scale=FALSE)
        [~,~,V] = svd(y);
        emat=V(:,size(y,2))';
        
        yorthreg=[emat, sum(emat.*mu)];
        % emat <- svd(y)$v[,dim(y)[2]]
        % return(c(emat, emat %*% attr(y, 'scaled:center')))
    end


    function outputsj=rlgaiterate(hpcoef, xsc, k, d, n, niter,alpha)
        
        % give the function the inital set of hyperplanes (in hpcoef)
        groups = rlgadodist(xsc, hpcoef, d, n,alpha);
        iter = 0;
        tabgrs=tabulate(groups);
        if min(tabgrs(:,2)< d) || length(unique(groups)) < k
            iter = niter+10;
        end
        
        converged = false;
        while (~converged && iter < niter)
            iter = iter+1;
            oldgroups = groups;
            for ii=1:k
                hpcoef(ii,:) = lgaorthreg(xsc(groups==ii,:));
            end
            groups = rlgadodist(xsc, hpcoef, d, n, alpha);
            
            tabgrs=tabulate(groups);
            if min(tabgrs(:,2))< d || length(unique(groups)) < k
                iter = (niter+10);
                % if there aren't enough obs in a group
            end
            
            if (isequal(oldgroups,groups))
                converged = true;
            end
        end
        ROSS=rlgacalculateROSS(hpcoef, xsc, n, d, groups);
        outputsj=[groups;converged;ROSS];
        
    end

    function indmin=rlgadodist(y, coeff, d, n,alpha)
   % This function calculates the (orthogonal) Residuals for different hyerplanes,
   % It calculates which hyperplane each observation is closest to, and then takes the
   % smallest alpha of them (setting the rest to zero)

        
        dist = (y * (coeff(:,1:d)')-ones(n,1)*(coeff(:,d+1)') ).^2;
        [distmin,indmin]=min(dist,[],2);
        indmin( distmin > quantile(distmin, alpha) ) = 0;
    end

    function ROSS=rlgacalculateROSS(hpcoef, xsc, n, d, groups)
        % This function calculates the total Residual Orthogonal Sum of
        % Squares for a given grouping
        z = bsxfun(@minus,xsc *(hpcoef(:,1:d)'), hpcoef(:,d+1)');
        dist = z.^2;
        
        seldis=groups>0;
        dist=dist(seldis,:);
        groups=groups(seldis);
        
        % modo alternativo per estrarre gli elementi di dist
        seq1=(1:length(groups))';
        
        ROSS=sum(dist((groups-1) * length(groups) + seq1));
    end


    function xbest=lgaCheckUnique(x)
        function zfin=CheckUniqueRand (z)
            zfin=sum(sum(z.^2))-0.5*(sum((sum(z,2)').^2)+ sum((sum(z,1)').^2));
        end
        
        d =size(x,2);
        
        index = true(d,1);
        for ii=1:(d-1)
            for jj =(ii+1):d
                y = crosstab(x(:,ii), x(:,jj));
                z = CheckUniqueRand(y);
                if (z==0)
                    index(jj) =  false;
                end
            end
        end
        if (sum(index) > 1)
            % In the incredibly unlikely situation....
            warning('FSDA:rlga:DuplicateSol','More than one unique solutions with identical ROSS -  returning first solution only')
            [~,index]=max(index);
            
        end
        
        xbest=x(:,index);
    end

end
%FScategory:CLUS-RobClaREG
