library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity scalar_mult is
    Generic ( WIDTH : integer := 32 );
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        k        : in  std_logic_vector(WIDTH-1 downto 0); 
        p_x, p_y : in  std_logic_vector(WIDTH-1 downto 0); 
        a_param  : in  std_logic_vector(WIDTH-1 downto 0); 
        modulus  : in  std_logic_vector(WIDTH-1 downto 0); 
        res_x, res_y : out std_logic_vector(WIDTH-1 downto 0);
        done     : out std_logic
    );
end scalar_mult;

architecture Behavioral of scalar_mult is

    component point_add is
        Generic ( WIDTH : integer );
        Port (
            clk      : in  std_logic; rst : in  std_logic; start    : in  std_logic;
            p1_x, p1_y : in  std_logic_vector(WIDTH-1 downto 0);
            p2_x, p2_y : in  std_logic_vector(WIDTH-1 downto 0);
            a_param  : in  std_logic_vector(WIDTH-1 downto 0);
            modulus  : in  std_logic_vector(WIDTH-1 downto 0);
            res_x, res_y : out std_logic_vector(WIDTH-1 downto 0);
            done     : out std_logic
        );
    end component;

    -- Yeni Durum: FIND_FIRST_BIT
    type state_type is (IDLE, FIND_FIRST_BIT, START_OP, WAIT_OP, NEXT_BIT, FINISH);
    signal state : state_type;
    
    signal pa_start, pa_done : std_logic;
    signal pa_p1x, pa_p1y, pa_p2x, pa_p2y : std_logic_vector(WIDTH-1 downto 0);
    signal pa_resx, pa_resy : std_logic_vector(WIDTH-1 downto 0);
    
    signal r_qx, r_qy : std_logic_vector(WIDTH-1 downto 0);
    signal bit_idx    : integer range -1 to WIDTH-1;
    signal do_add     : std_logic;

begin

    U_POINT_OP: point_add generic map (WIDTH => WIDTH)
        port map (
            clk => clk, rst => rst, start => pa_start,
            p1_x => pa_p1x, p1_y => pa_p1y,
            p2_x => pa_p2x, p2_y => pa_p2y,
            a_param => a_param, modulus => modulus,
            res_x => pa_resx, res_y => pa_resy,
            done => pa_done
        );

    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE; done <= '0'; pa_start <= '0';
            r_qx <= (others => '0'); r_qy <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        bit_idx <= WIDTH - 1; -- En tepeden aramaya başla
                        state <= FIND_FIRST_BIT;
                    end if;

                -- BAŞTAKİ SIFIRLARI ATLA
                when FIND_FIRST_BIT =>
                    if k(bit_idx) = '1' then
                        r_qx <= p_x; r_qy <= p_y; -- İlk '1' bulundu, Q = P yap
                        if bit_idx = 0 then
                            state <= FINISH; -- Sadece 1 bitlik bir k ise bitir
                        else
                            bit_idx <= bit_idx - 1;
                            do_add <= '0';
                            state <= START_OP;
                        end if;
                    else
                        if bit_idx = 0 then
                            state <= FINISH; -- k = 0 durumu (geçersiz ama güvenli çıkış)
                        else
                            bit_idx <= bit_idx - 1; -- Sıfır bitini geç
                        end if;
                    end if;

                when START_OP =>
                    pa_p1x <= r_qx; pa_p1y <= r_qy;
                    if do_add = '1' then
                        pa_p2x <= p_x; pa_p2y <= p_y; -- Add adımı
                    else
                        pa_p2x <= r_qx; pa_p2y <= r_qy; -- Double adımı
                    end if;
                    pa_start <= '1';
                    state <= WAIT_OP;

                when WAIT_OP =>
                    pa_start <= '0';
                    if pa_done = '1' then
                        r_qx <= pa_resx; r_qy <= pa_resy;
                        if do_add = '0' and k(bit_idx) = '1' then
                            do_add <= '1';
                            state <= START_OP;
                        else
                            do_add <= '0';
                            state <= NEXT_BIT;
                        end if;
                    end if;

                when NEXT_BIT =>
                    if bit_idx = 0 then
                        state <= FINISH;
                    else
                        bit_idx <= bit_idx - 1;
                        state <= START_OP;
                    end if;

                when FINISH =>
                    res_x <= r_qx; res_y <= r_qy;
                    done <= '1';
                    state <= IDLE;

                when others => state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;