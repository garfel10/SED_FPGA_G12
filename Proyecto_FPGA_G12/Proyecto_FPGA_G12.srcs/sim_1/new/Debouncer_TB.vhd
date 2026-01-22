library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Debouncer_TB is
-- Entity vacía para testbench
end Debouncer_TB;

architecture Behavioral of Debouncer_TB is

    -- Componente a probar
    component Debouncer is
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               btn_in : in STD_LOGIC;
               btn_out : out STD_LOGIC );
    end component;

    -- Señales
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal btn_in : std_logic := '0';
    signal btn_out : std_logic;

    -- Periodo de reloj (10 ns = 100 MHz)
    constant clk_period : time := 10 ns;

begin

    -- Conectar el componente (UUT)
    uut: Debouncer port map (
        clk => clk,
        reset => reset,
        btn_in => btn_in,
        btn_out => btn_out
    );

    -- Proceso de reloj
    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Proceso de estímulos (Simular botón con rebotes)
    stim_proc: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- SIMULACIÓN DE REBOTES (Ruido)
        -- Pulsamos el botón pero tiembla el dedo
        btn_in <= '1'; wait for 20 ns; 
        btn_in <= '0'; wait for 10 ns;
        btn_in <= '1'; wait for 20 ns;
        btn_in <= '0'; wait for 10 ns;
        
        -- Ahora lo dejamos pulsado firmemente
        btn_in <= '1'; 
        wait for 50 ms; -- Tiempo largo para que el debouncer reaccione

        -- Soltamos el botón (con rebotes también)
        btn_in <= '0'; wait for 20 ns;
        btn_in <= '1'; wait for 10 ns;
        btn_in <= '0';
        
        wait;
    end process;

end Behavioral;
