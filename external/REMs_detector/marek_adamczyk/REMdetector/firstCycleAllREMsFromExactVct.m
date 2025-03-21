function [allREMsNb funName remEpochs]= firstCycleAllREMsFromExactVct(hip, epochLength, exactREMsVct, sampling)


funName = '1stCycleAR';


hipLen = length(hip);


if hipLen > length(exactREMsVct)/sampling/epochLength
    
   fprintf('Vector is shorter than hipnogram!!!\n');     
   hipLen = floor(length(exactREMsVct)/sampling/epochLength);
   
end

[result groupsNames] = findSleepCycles(hip, epochLength);
placeInHip = floor(result/epochLength);

placeInHip(placeInHip >numel(hip)) = repmat(numel(hip),numel(placeInHip(placeInHip >numel(hip))),1);

begin = placeInHip(1, 1);
eend = placeInHip(1, 2) ;


remEpochs = 0;
allREMsNb = 0;

for i = begin:1:eend
        
    if hip(i) == 5
             
        placeInExtVctBeg = (i-1)*sampling*epochLength + 1;
        placeInExtVctEnd = i*sampling*epochLength;

        currentFragment = exactREMsVct(placeInExtVctBeg:placeInExtVctEnd);
        REMsInCurrFrag = 0;
        previousREM = 0;
        
%        currentFragment'
        
        for jj = 1:1:length(currentFragment)
        
            
            if currentFragment(jj) > 0 

                if ~previousREM
            
                    previousREM = 1;                
                    REMsInCurrFrag = REMsInCurrFrag + 1;               

                end
                
            else
                
                previousREM = 0;
                
            end            
            
        end % for jj = 1:1:length(currentFragment)
        
        allREMsNb = allREMsNb + REMsInCurrFrag;
        remEpochs = remEpochs+1;
        
    end % if hip(i) == 5       
    
end % for i = 1:1:hipLen


end % function [...] = allNightAllREMsFromExactVct(...)

