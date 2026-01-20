library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Debouncer is
    Port (
        clk        : in  STD_LOGIC; -- Reloj del sistema (100 MHz)
        reset      : in  STD_LOGIC; -- Reinicio asíncrono
        btn_in     : in  STD_LOGIC; -- Entrada directa del botón (con rebotes)
        btn_out    : out STD_LOGIC  -- Salida filtrada (genera un único pulso limpio)
    );
end Debouncer;

architecture Behavioral of Debouncer is
    -- Calculamos los ciclos necesarios para esperar 10ms
    -- 100 MHz = 10ns por ciclo -> 1,000,000 ciclos * 10ns = 10ms
    constant DEBOUNCE_LIMIT : integer := 1000000;
    
    -- Señales internas
    signal counter : integer range 0 to DEBOUNCE_LIMIT := 0; -- Contador de tiempo de estabilidad
    signal btn_prev : std_logic := '0';    -- Estado anterior inmediato para detectar cambios
    signal btn_stable : std_logic := '0';  -- Estado estable almacenado y verificado

begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            btn_prev <= '0';
            btn_stable <= '0';
            btn_out <= '0';
            
        elsif rising_edge(clk) then
            -- Por defecto la salida es 0 (lógica de pulso único)
            btn_out <= '0'; 

            -- Si la entrada actual es diferente a la anterior, hay ruido o cambio
            if (btn_prev /= btn_in) then
                counter <= 0;        -- Reiniciamos el contador si hay actividad
                btn_prev <= btn_in;  -- Actualizamos el estado previo
                
            -- Si la entrada no ha cambiado, contamos tiempo
            elsif (counter < DEBOUNCE_LIMIT) then
                counter <= counter + 1;
                
            else
                -- Si el contador llega al límite, la señal es estable
                -- Comprobamos si el nuevo estado estable es diferente al que teníamos guardado
                if (btn_stable /= btn_in) then
                    btn_stable <= btn_in; -- Actualizamos el estado estable
                    
                    -- Si el nuevo estado es '1' (botón presionado), mandamos el pulso
                    if btn_in = '1' then
                        btn_out <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;