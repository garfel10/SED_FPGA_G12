library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Display_Controller is
    Port (
        clk_disp      : in  STD_LOGIC; -- Reloj de refresco (aprox 1 kHz) generado en Clock_Divider
        reset         : in  STD_LOGIC; -- Reset global
        
        -- Entrada de datos completa: 64 bits que contienen la información de los 8 displays.
        -- Cada bloque de 8 bits representa un dígito/patrón completo.
        segments_data : in  STD_LOGIC_VECTOR (63 downto 0); 
        
        anodes        : out STD_LOGIC_VECTOR (7 downto 0); -- Controla qué display se enciende
        cathodes      : out STD_LOGIC_VECTOR (6 downto 0)  -- Controla qué segmentos se iluminan (A-G)
    );
end Display_Controller;

architecture Behavioral of Display_Controller is
    
    -- Contador que va del 0 al 7 para recorrer los 8 displays secuencialmente
    signal sel_ctr : integer range 0 to 7 := 0; 
    
    -- Almacena temporalmente los segmentos del display que está activo en este instante
    signal current_segments : std_logic_vector(7 downto 0); 

begin

    -- Proceso 1: Contador de Barrido
    -- Este proceso cambia el display activo cada vez que llega un pulso de reloj.
    -- Al hacerlo muy rápido, el ojo humano cree que todos están encendidos a la vez.
    process(clk_disp, reset)
    begin
        if reset = '1' then
            sel_ctr <= 0;
        elsif rising_edge(clk_disp) then
            if sel_ctr = 7 then
                sel_ctr <= 0; -- Vuelta a empezar
            else
                sel_ctr <= sel_ctr + 1; -- Siguiente display
            end if;
        end if;
    end process;

    -- Proceso 2: Selector de Ánodos y Datos (Multiplexor)
    process(sel_ctr, segments_data)
    begin
        -- Primero apagamos todos los displays (lógica negativa: '1' es apagado)
        anodes <= "11111111"; 
        
        -- Ahora encendemos SOLO el display que toca según el contador sel_ctr
        -- y cargamos los datos correspondientes a ese display específico.
        case sel_ctr is
            when 0 => 
                anodes(0) <= '0'; -- Encender Display 0 (Derecha)
                current_segments <= segments_data(7 downto 0);
            when 1 => 
                anodes(1) <= '0';
                current_segments <= segments_data(15 downto 8);
            when 2 => 
                anodes(2) <= '0';
                current_segments <= segments_data(23 downto 16);
            when 3 => 
                anodes(3) <= '0';
                current_segments <= segments_data(31 downto 24);
            when 4 => 
                anodes(4) <= '0';
                current_segments <= segments_data(39 downto 32);
            when 5 => 
                anodes(5) <= '0';
                current_segments <= segments_data(47 downto 40);
            when 6 => 
                anodes(6) <= '0';
                current_segments <= segments_data(55 downto 48);
            when 7 => 
                anodes(7) <= '0'; -- Encender Display 7 (Izquierda)
                current_segments <= segments_data(63 downto 56);
        end case;
    end process;

    -- Proceso 3: Salida física a los Cátodos
    -- Invertimos la señal (NOT) porque los displays de 7 segmentos son de cátodo común.
    -- En el hardware: '0' enciende el LED, '1' lo apaga.
    -- En nuestra lógica interna: '1' significa pixel encendido.
    cathodes <= not current_segments(6 downto 0); 

end Behavioral;
