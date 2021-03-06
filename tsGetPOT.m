function [POTdata]=tsGetPOT(ms,pcts,desiredEventsPerYear, varargin)
% function POTdata=tsGetPOT(ms,pcts,desiredEventsPerYear)
% Gets POT using an automatic threshold such that the mean number of events per year is equal to desiredEventsPerYear
% 
% INPUTS:
% ms  data in two columns sdate and values. IT IS ASSUMED
% pcts    vestor of percentiles tested
% desiredEventsPerYear    mean number of events per year
% 
% Michalis Vousdoukas, Evangelos Voukouvalas, Lorenzo Mentaschi 2015


% get number of years
% nyears=(nanmax(ms(:,1))-nanmin(ms(:,1)))/365;

args.minPeakDistanceInDays = -1;
args = tsEasyParseNamedArgs(varargin, args);
minPeakDistanceInDays = args.minPeakDistanceInDays;
if minPeakDistanceInDays == -1
    error('label parameter ''minPeakDistanceInDays'' must be set')
end

dt = tsEvaGetTimeStep(ms(:,1));
minPeakDistance = minPeakDistanceInDays/dt;

nyears=nanmin(diff(ms(:,1)))*length(ms(~isnan(ms(:,2)),1))/365;

if length(pcts) == 1
    % testing at least 2 percentages, to be able to compute the error on
    % the percentage.
    pcts = [pcts(1) - 3, pcts(1)];
    % if there is only one percentile that means that the user does not
    % want to look for n peaks every year. Setting therefore
    % desiredEventsPerYear to -1;
    desiredEventsPerYear = -1;
end

numperyear=nan(length(pcts),1);
minnumperyear=nan(length(pcts),1);
thrsdts=nan(length(pcts),1);

for ipp=1:length(pcts)

    disp(['Finding optimal threshold ' num2str(100*ipp/length(pcts)) '%...']);

    thrsdt=prctile(ms(:,2),pcts(ipp));
    thrsdts(ipp) = thrsdt;

    [pks,locs] = findpeaks(ms(:,2),'MinPeakDistance',minPeakDistance,'MinPeakHeight',thrsdt);

    %     for POT
    numperyear(ipp)=length(pks)/nyears;

%     for R-largest
    nperYear=tsGetNumberPerYear(ms,locs);
    minnumperyear(ipp)=nanmin(nperYear);

    if (ipp > 1) && (length(pks)/nyears<desiredEventsPerYear) && (nanmin(nperYear)<desiredEventsPerYear)

        break

    end
end

% evaluating the error on the threshold
diffNPerYear = nanmean(diff(flipud(numperyear)));
if diffNPerYear == 0
  diffNPerYear = 1;
end
thresholdError = nanmean(diff(thrsdts)/diffNPerYear)/2;

%% Use optimal for POT
indexp=nanmax(find(numperyear>desiredEventsPerYear==1));

try

  if ~isempty(indexp)
      thrsd = prctile(ms(:,2),pcts(indexp)); % threshold is the 99.9th percentile of the timeseries;
      pct = pcts(indexp);
  else
      thrsd = 0;
      pct = 0;
  end

  % figure(1)
  % plot(pcts,numperyear,pcts,minnumperyear,'r')
  % 
  % figure;plot(ms(:,1),ms(:,2));
  % horizontal_lines(thrsd)


  [pks,locs] = findpeaks(ms(:,2),'MinPeakDistance',minPeakDistance,'MinPeakHeight',thrsd);

  POTdata.threshold=thrsd;
  POTdata.thresholdError = thresholdError;
  POTdata.percentile=pct;
  POTdata.peaks=pks;
  POTdata.ipeaks=locs;
  POTdata.sdpeaks=ms(locs,1);

catch exc
  POTdata = [];
  disp(getReport(exc));
end
