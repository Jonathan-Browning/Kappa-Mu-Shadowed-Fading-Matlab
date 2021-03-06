classdef KappaMuShadowed
    %KappaMuShadowed This class holds all the parameters for the \kappa-\mu fading model.
    % It calculates theoretical envelope PDF
    % It does a Monte Carlo simulation using the parameters
    
    properties(Constant, Hidden = true)
        NumSamples = 2E6; % number of samples
        r = 0:0.001:6 % envelope range for PDF ploteter
    end 
    
    properties(Access = public)
        kappa; 
        m; % shadowing severity
        mu; % number of clusters
        r_hat; % root mean square of the signal
    end
    
    properties(Hidden = true) 
        multipathFading; % Found based on the inputs
        envelopeProbability; % Calculated theoretical envelope probability
        xdataEnv; % Simulated envelope density plot x values 
        ydataEnv; % Simlated envelope density plot y valyes
    end
    
    methods(Access = public)
        function obj = KappaMuShadowed(kappa,m,mu,r_hat)
            
            %   Assigning input values
            obj.kappa = input_Check(obj,kappa,'\kappa',0,50);
            obj.m = input_Check(obj,m,'m',0.001,50);
            obj.mu = input_Check(obj,mu,'\mu',1,10);
            obj.r_hat = input_Check(obj,r_hat,'\hat{r}^2',0.5,2.5);
            
            % other calculated properties
            obj.multipathFading = Multipath_Fading(obj);
            obj.envelopeProbability = envelope_PDF(obj);
            [obj.xdataEnv, obj.ydataEnv] = envelope_Density(obj);
        end
    end
    
    methods(Access = private)
        
        function data = input_Check(obj, data, name, lower, upper) 
            % intput_Check checks the user inputs and throws errors
            
            % checks if input is empty
            if isempty(data)
                error(strcat(name,' must be a numeric input'));
            end
            
            % inputs must be a number
            if ~isnumeric(data)
               error(strcat(name,' must be a number, not a %s.', class(data)));
            end
            
            % input must be within the range
            if data < lower || data > upper
               error(strcat(name,' must be in the range [',num2str(lower),', ',num2str(upper),'].'));
            end
            
            % mu must be integer
            if strcmp(name,'\mu') && mod(data, 1) ~= 0
                error(strcat(name,' must be an integer'));
            end
                
        end
        
        function [p_i, q_i] = means(obj)
            %means Calculates the means of the complex Gaussians 
            %representing the in-phase and quadrature components.

            d2 = (obj.r_hat^(2) * obj.kappa)/(1 + obj.kappa);
     
            p_i = sqrt(d2/(2.*obj.mu));
            q_i = p_i;
            
        end
        
        function [sigma2] = scattered_Component(obj)
            %scattered_Component Calculates the power of the scattered 
            %signal component.    
            
            sigma2 = obj.r_hat.^(2) ./(2 * obj.mu .* (1 + obj.kappa));
            
        end
        
        function [gaussians] = generate_Gaussians(obj, mean, sigma) 
            %generate_Gaussians Generates the Gaussian random variables 
            
            gaussians = normrnd(mean,sigma,[1,obj.NumSamples]);
        end
        
        function [multipathFading] = Multipath_Fading(obj) 
            %complex_MultipathFading Generates the random variables
            
            [p_i, q_i] = means(obj);
            [sigma2] = scattered_Component(obj);
            
            xi = sqrt(gamrnd(obj.m,1./obj.m,[1,obj.NumSamples]));
            
            multipathFading = 0;
            for i = 1 : 1 : obj.mu
                X_i = generate_Gaussians(obj, xi*p_i, sqrt(sigma2));
                Y_i = generate_Gaussians(obj, xi*q_i, sqrt(sigma2));

                multipathFading = multipathFading + X_i.^(2) + Y_i.^(2);
            end 
            
        end    
        
        function [eProbTheor] = envelope_PDF(obj)
            %envelope_PDF Calculates the theoretical envelope PDF   
            
            R = obj.r ./ obj.r_hat;
            A = (2 .* obj.r.^((2*obj.mu) -1) .* obj.mu^obj.mu .* obj.m^obj.m .* (1+obj.kappa)^obj.mu) ./ ...
                (gamma(obj.mu) .* ((obj.mu*obj.kappa)+obj.m)^obj.m .* obj.r_hat^(2*obj.mu));
            B = exp(- obj.mu .* (1+obj.kappa) .* R.^2);
            C = kummer(obj.m, obj.mu, ((obj.mu^2 * obj.kappa * (1+obj.kappa))/ ((obj.mu*obj.kappa)+obj.m)) .* R.^2);

            eProbTheor = A .* B .* C;

        end
        
        function [xdataEnv, ydataEnv] = envelope_Density(obj)
            %envelope_Density Evaluates the envelope PDF
            R = sqrt(obj.multipathFading);

            [f,x] = ecdf(R);
            [ydataEnv, xdataEnv] = ecdfhist(f,x, 0:0.05:max(obj.r));
            
        end
            
    end
end

