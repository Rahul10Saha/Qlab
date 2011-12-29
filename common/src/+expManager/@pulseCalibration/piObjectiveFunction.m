function [cost, J] = piObjectiveFunction(obj, x, qubit, direction)
    piAmp = x(1);
    offset = x(2);
    fprintf('piAmp: %.0f, offset: %.3f\n', piAmp, offset);
    % create and load sequence
    obj.pulseParams.piAmp = piAmp;
    [filenames nbrPatterns] = obj.PiCalChannelSequence(obj.ExpParams.Qubit, direction);
    if ~obj.testMode
        obj.loadSequence(filenames);
    end
    
    % set channel offset
    IQchannels = obj.channelMap(qubit);
    switch direction
        case 'X'
            chan = num2str(IQchannels{1});
            %offset = obj.pulseParams.i_offset;
        case 'Y'
            chan = num2str(IQchannels{2});
            %offset = obj.pulseParams.q_offset;
        otherwise
            error('Unknown direction %s', direction);
    end
    if ~obj.testMode
        awg = obj.awg{1};
        awg.(['chan_' chan]).offset = offset;
    end
    
    % measure
    if ~obj.testMode
        data = obj.homodyneMeasurement(nbrPatterns);
    else
        data = simulateMeasurement(x);
        plot(data);
        ylim([.49 .81])
        pause(.1);
    end
    
    % evaluate cost
    [cost, J] = obj.RepPulseCostFunction(data, pi);
    % scale J rows by amplitude and offset->amplitude conversion factor
    J(:,1) = J(:,1)/piAmp;
    offset2amp = 8192/2.0; % replace 2.0 by the max output voltage of the AWG
    J(:,2) = J(:,2)*offset2amp/piAmp;
    fprintf('Cost: %.4f (%.4f) \n', sum(cost.^2), sum(cost.^2/length(cost)));
end

function data = simulateMeasurement(x)
    idealAmp = 7100;
    idealOffset = .124;
    
    amp = x(1);
    offset = x(2);
    
    % amp = 8192 <=> offset 2.0
    off2Amp = 8192/2.0;
    offsetError = off2Amp*(offset - idealOffset);
    ampError = (amp + offsetError - idealAmp)/idealAmp;
    ampError2 = (amp - offsetError - idealAmp)/idealAmp;
    angleError = ampError*pi;
    angleError2 = ampError2*pi;
    
    % data representing amplitude error
    n = 1:9;
    data = 0.65 + 0.15*(-1).^n .* sin((n-1) * angleError);
    data2 = 0.65 + 0.15*(-1).^n .* sin((n-1) * angleError2);
    % double every point
    data = data(floor(1:.5:9.5));
    data2 = data2(floor(1:.5:9.5));
    data = [0.5 0.5 data data2];
end