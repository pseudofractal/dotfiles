function u = astro_units()
  % astro_units
  % Returns unit conversion factors and helpers.

  u = struct();

  % --- Energy ---
  u.ev2j  = @(x) x * 1.602176634e-19;
  u.j2ev  = @(x) x / 1.602176634e-19;
  u.ev2erg = @(x) x * 1.602176634e-12;
  u.erg2ev = @(x) x / 1.602176634e-12;

  % --- Temperature ---
  u.k2ev = @(x) x * 8.617333262145e-5;   % eV/K
  u.ev2k = @(x) x / 8.617333262145e-5;

  % --- Distance ---
  u.au2m = @(x) x * 1.495978707e11;
  u.m2au = @(x) x / 1.495978707e11;

  u.pc2m = @(x) x * 3.085677581491367e16;
  u.m2pc = @(x) x / 3.085677581491367e16;

  u.ly2m = @(x) x * 9.4607304725808e15;
  u.m2ly = @(x) x / 9.4607304725808e15;

  % --- Mass ---
  u.msun2kg = @(x) x * 1.98847e30;
  u.kg2msun = @(x) x / 1.98847e30;

  u.mearth2kg = @(x) x * 5.9722e24;
  u.kg2mearth = @(x) x / 5.9722e24;

  u.mjup2kg = @(x) x * 1.89813e27;
  u.kg2mjup = @(x) x / 1.89813e27;

  % --- CGS/SI conversions ---
  u.erg2j = @(x) x * 1e-7;
  u.j2erg = @(x) x * 1e7;

  u.cm2m = @(x) x * 1e-2;
  u.m2cm = @(x) x * 1e2;

  u.g2kg = @(x) x * 1e-3;
  u.kg2g = @(x) x * 1e3;

  % --- Flux ---
  u.wm2_to_erg_cm2_s = @(x) x * 1e3;    % W/m^2 -> erg/s/cm^2
  u.erg_cm2_s_to_wm2 = @(x) x * 1e-3;

  % --- Angles ---
  u.deg2rad = @(x) x * pi/180;
  u.rad2deg = @(x) x * 180/pi;
  u.arcsec2rad = @(x) x * (pi/180/3600);
  u.rad2arcsec = @(x) x / (pi/180/3600);
end
