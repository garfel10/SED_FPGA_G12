library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top_Game is
    Port (
        CLK100MHZ  : in  STD_LOGIC; -- Entrada del oscilador de la placa (100 MHz)
        CPU_RESETN : in  STD_LOGIC; -- Botón de Reset rojo (funciona al revés: 0 es pulsado)
        
        -- Botones físicos de control
        BTNU : in STD_LOGIC; -- Pulsador Arriba
        BTND : in STD_LOGIC; -- Pulsador Abajo
       
        -- Salidas hacia los periféricos de la placa
        AN  : out STD_LOGIC_VECTOR (7 downto 0);  -- Ánodos: Seleccionan qué display se enciende
        CA  : out STD_LOGIC_VECTOR (6 downto 0);  -- Cátodos: Encienden los segmentos A-G
        LED : out STD_LOGIC_VECTOR (15 downto 0)  -- LEDs verdes para vidas y efectos
    );
end Top_Game;

architecture Behavioral of Top_Game is

    -- 1. CABLES INTERNOS (SIGNALS)
    -- Estas señales actúan como cables virtuales para unir unos módulos con otros.
    
    signal reset_sys : std_logic;       -- Reset invertido (para que funcione con lógica positiva)
    signal clk_disp_wire : std_logic;   -- Cable del reloj lento para los displays
    signal game_tick_wire : std_logic;  -- Cable del pulso de velocidad del juego
    
    signal btn_up_clean : std_logic;    -- Señal del botón ARRIBA limpia (sin rebotes)
    signal btn_down_clean : std_logic;  -- Señal del botón ABAJO limpia (sin rebotes)
    
    signal rnd_wire : std_logic_vector(7 downto 0);      -- Cable con el número aleatorio
    signal segments_wire : std_logic_vector(63 downto 0); -- Cable con los datos de imagen para los displays
    
    -- 2. DECLARACIÓN DE COMPONENTES
    -- Aquí listamos las "piezas" que vamos a usar en el circuito.
    
    component Clock_Divider is
        Port ( clk_100MHz : in STD_LOGIC; reset : in STD_LOGIC;
               clk_disp : out STD_LOGIC; game_tick : out STD_LOGIC );
    end component;
    
    component Debouncer is
        Port ( clk : in STD_LOGIC; reset : in STD_LOGIC;
               btn_in : in STD_LOGIC; btn_out : out STD_LOGIC );
    end component;
    
    component LFSR is
        Port ( clk : in STD_LOGIC; reset : in STD_LOGIC;
               rnd_out : out STD_LOGIC_VECTOR(7 downto 0) );
    end component;
    
    component Game_Logic is
        Port ( clk : in STD_LOGIC; reset : in STD_LOGIC; game_tick : in STD_LOGIC;
               btn_up : in STD_LOGIC; btn_down : in STD_LOGIC;
               rnd_in : in STD_LOGIC_VECTOR(7 downto 0);
               segments_out : out STD_LOGIC_VECTOR(63 downto 0);
               leds_out : out STD_LOGIC_VECTOR(15 downto 0) );
    end component;
    
    component Display_Controller is
        Port ( clk_disp : in STD_LOGIC; reset : in STD_LOGIC;
               segments_data : in STD_LOGIC_VECTOR(63 downto 0);
               anodes : out STD_LOGIC_VECTOR(7 downto 0);
               cathodes : out STD_LOGIC_VECTOR(6 downto 0) );
    end component;

begin

    -- Adaptación del Reset:
    -- El botón de la placa (CPU_RESETN) da un '0' cuando se pulsa.
    -- Nuestra lógica interna espera un '1' para resetear. Por eso usamos NOT.
    reset_sys <= not CPU_RESETN;

    -- 3. INSTANCIACIÓN Y CONEXIONES (PORT MAPS)
    -- Aquí "soldamos" los cables internos a los puertos de cada módulo.
    
    -- Módulo de Relojes: Genera los ritmos del sistema
    U1_Clocks: Clock_Divider 
    port map (
        clk_100MHz => CLK100MHZ,
        reset      => reset_sys,
        clk_disp   => clk_disp_wire,  -- Salida hacia el Display Controller
        game_tick  => game_tick_wire  -- Salida hacia el Game Logic
    );

    -- Filtro para el botón ARRIBA
    U2_Debouncer_Up: Debouncer
    port map (
        clk     => CLK100MHZ,
        reset   => reset_sys,
        btn_in  => BTNU,         -- Entrada física
        btn_out => btn_up_clean  -- Salida limpia
    );

    -- Filtro para el botón ABAJO (Reutilizamos el mismo diseño de Debouncer)
    U3_Debouncer_Down: Debouncer
    port map (
        clk     => CLK100MHZ,
        reset   => reset_sys,
        btn_in  => BTND,
        btn_out => btn_down_clean
    );

    -- Generador de Números Aleatorios
    U4_Random: LFSR
    port map (
        clk     => CLK100MHZ,
        reset   => reset_sys,
        rnd_out => rnd_wire      -- Número aleatorio hacia el Game Logic
    );

    -- El Cerebro del Juego: Procesa toda la información
    U5_Logic: Game_Logic
    port map (
        clk          => CLK100MHZ,
        reset        => reset_sys,
        game_tick    => game_tick_wire,
        btn_up       => btn_up_clean,
        btn_down     => btn_down_clean,
        rnd_in       => rnd_wire,
        segments_out => segments_wire, -- Manda la imagen generada al controlador
        leds_out     => LED            -- Conexión directa a los LEDs físicos
    );

    -- Controlador de Pantalla: Dibuja la información en los 7 segmentos
    U6_Display: Display_Controller
    port map (
        clk_disp      => clk_disp_wire,
        reset         => reset_sys,
        segments_data => segments_wire, -- Recibe la imagen desde Game Logic
        anodes        => AN,            -- Conexión física a los Ánodos
        cathodes      => CA             -- Conexión física a los Cátodos
    );

end Behavioral;