function c = astro_constants()
  % astro_constants
  % Returns physical constants and astronomy constants in nested structs.
  % SI units in c.SI, CGS units in c.CGS.
  % Astronomy constants in c.Astro.SI and c.Astro.CGS.
  % Cosmology defaults (Planck 2018) in c.Cosmo.

  c = struct();

  % --- Core SI constants ---
  c.SI = struct();
  c.SI.c        = 299792458;                % m s^-1
  c.SI.G        = 6.67430e-11;              % m^3 kg^-1 s^-2
  c.SI.h        = 6.62607015e-34;           % J s
  c.SI.hbar     = c.SI.h/(2*pi);            % J s
  c.SI.kB       = 1.380649e-23;             % J K^-1
  c.SI.sigma    = 5.670374419e-8;           % W m^-2 K^-4
  c.SI.e        = 1.602176634e-19;          % C
  c.SI.epsilon0 = 8.8541878128e-12;         % F m^-1
  c.SI.mu0      = 1.25663706212e-6;         % N A^-2
  c.SI.Na       = 6.02214076e23;            % mol^-1
  c.SI.R        = 8.314462618;              % J mol^-1 K^-1

  % --- Particle masses (SI) ---
  c.SI.m_e = 9.1093837015e-31;              % kg
  c.SI.m_p = 1.67262192369e-27;             % kg
  c.SI.m_n = 1.67492749804e-27;             % kg

  % --- Core CGS constants ---
  c.CGS = struct();
  c.CGS.c        = 2.99792458e10;           % cm s^-1
  c.CGS.G        = 6.67430e-8;              % cm^3 g^-1 s^-2
  c.CGS.h        = 6.62607015e-27;          % erg s
  c.CGS.hbar     = c.CGS.h/(2*pi);          % erg s
  c.CGS.kB       = 1.380649e-16;            % erg K^-1
  c.CGS.sigma    = 5.670374419e-5;          % erg cm^-2 s^-1 K^-4
  c.CGS.e        = 4.803204712570263e-10;   % statC
  c.CGS.Na       = c.SI.Na;                 % mol^-1
  c.CGS.R        = 8.314462618e7;           % erg mol^-1 K^-1

  % --- Particle masses (CGS) ---
  c.CGS.m_e = 9.1093837015e-28;             % g
  c.CGS.m_p = 1.67262192369e-24;            % g
  c.CGS.m_n = 1.67492749804e-24;            % g

  % --- Astronomy constants ---
  c.Astro = struct();
  c.Astro.SI = struct();
  c.Astro.CGS = struct();

  % Distances
  c.Astro.SI.AU  = 1.495978707e11;          % m
  c.Astro.SI.pc  = 3.085677581491367e16;    % m
  c.Astro.SI.ly  = 9.4607304725808e15;      % m
  c.Astro.CGS.AU = 1.495978707e13;          % cm
  c.Astro.CGS.pc = 3.085677581491367e18;    % cm
  c.Astro.CGS.ly = 9.4607304725808e17;      % cm

  % Solar
  c.Astro.SI.M_sun = 1.98847e30;            % kg
  c.Astro.SI.R_sun = 6.957e8;               % m
  c.Astro.SI.L_sun = 3.828e26;              % W
  c.Astro.SI.T_sun = 5772;                  % K
  c.Astro.CGS.M_sun = 1.98847e33;           % g
  c.Astro.CGS.R_sun = 6.957e10;             % cm
  c.Astro.CGS.L_sun = 3.828e33;             % erg s^-1
  c.Astro.CGS.T_sun = 5772;                 % K

  % Earth
  c.Astro.SI.M_earth = 5.9722e24;           % kg
  c.Astro.SI.R_earth = 6.371e6;             % m
  c.Astro.CGS.M_earth = 5.9722e27;          % g
  c.Astro.CGS.R_earth = 6.371e8;            % cm

  % Jupiter
  c.Astro.SI.M_jup = 1.89813e27;            % kg
  c.Astro.SI.R_jup = 6.9911e7;              % m
  c.Astro.CGS.M_jup = 1.89813e30;           % g
  c.Astro.CGS.R_jup = 6.9911e9;             % cm

  % --- Cosmology (Planck 2018 defaults) ---
  c.Cosmo = struct();
  c.Cosmo.H0_km_s_Mpc = 67.4;               % km s^-1 Mpc^-1
  c.Cosmo.Omega_m     = 0.315;
  c.Cosmo.Omega_Lambda= 0.685;

  % Derived cosmology values (SI)
  c.Cosmo.H0_SI = (c.Cosmo.H0_km_s_Mpc * 1000) / c.Astro.SI.pc / 1e6; % s^-1
  c.Cosmo.rho_crit = 3 * c.Cosmo.H0_SI^2 / (8*pi*c.SI.G);            % kg m^-3
end
