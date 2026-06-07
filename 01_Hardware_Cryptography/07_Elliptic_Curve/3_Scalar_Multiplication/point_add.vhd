library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity point_add is
    Generic ( WIDTH : integer := 32 );
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        p1_x, p1_y : in  std_logic_vector(WIDTH-1 downto 0);
        p2_x, p2_y : in  std_logic_vector(WIDTH-1 downto 0);
        a_param    : in  std_logic_vector(WIDTH-1 downto 0); -- Eliptik eğri 'a' parametresi
        modulus    : in  std_logic_vector(WIDTH-1 downto 0);
        res_x, res_y : out std_logic_vector(WIDTH-1 downto 0);
        done       : out std_logic
    );
end point_add;

architecture Behavioral of point_add is

    -- Bileşen Tanımları
    component mod_exp is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk : in std_logic; rst : in std_logic; start : in std_logic;
            start_value : in std_logic_vector(DATA_WIDTH-1 downto 0);
            base : in std_logic_vector(DATA_WIDTH-1 downto 0);
            exp : in std_logic_vector(DATA_WIDTH-1 downto 0);
            modulus : in std_logic_vector(DATA_WIDTH-1 downto 0);
            result : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done : out std_logic
        );
    end component;

    component mon_pro is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk : in std_logic; rst : in std_logic; start : in std_logic;
            a_in, b_in, n_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
            result : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done : out std_logic
        );
    end component;

    -- Durum Makinesi Tipleri
    type state_type is (IDLE, PREP_DOUBLE_1, START_INV, WAIT_INV, 
                        START_LAMBDA, WAIT_LAMBDA, START_X3_SQ, WAIT_X3_SQ, 
                        CALC_X3, START_Y3_MULT, WAIT_Y3_MULT, FINISH);
    signal state : state_type;
    
    -- Debug Sinyali: WaveTrace'de 'state' görünmezse bunu izle
    signal state_num : integer range 0 to 15;

    -- Kontrol ve Veri Sinyalleri
    signal me_start, me_done, mp_start, mp_done : std_logic;
    signal me_res, mp_a, mp_b, mp_res : std_logic_vector(WIDTH-1 downto 0);
    signal r_num, r_den, r_lambda, r_x3 : std_logic_vector(WIDTH-1 downto 0);
    signal r_p_minus_2 : std_logic_vector(WIDTH-1 downto 0);
    signal is_doubling : std_logic;

    -- Düzeltilmiş Modüler Yardımcı Fonksiyonlar
    function mod_sub(a, b, m : unsigned) return std_logic_vector is
        variable res : unsigned(WIDTH-1 downto 0);
    begin
        if a >= b then res := a - b;
        else res := (a + m) - b; end if;
        return std_logic_vector(res);
    end function;

    function mod_add(a, b, m : unsigned) return std_logic_vector is
        variable sum : unsigned(WIDTH downto 0);
        variable res : unsigned(WIDTH-1 downto 0);
    begin
        sum := resize(a, WIDTH+1) + resize(b, WIDTH+1);
        if sum >= resize(m, WIDTH+1) then 
            res := resize(sum - resize(m, WIDTH+1), WIDTH);
        else 
            res := resize(sum, WIDTH); 
        end if;
        return std_logic_vector(res);
    end function;

begin

    -- Fermat'nın Küçük Teoremi için Üs (p-2)
    r_p_minus_2 <= std_logic_vector(unsigned(modulus) - 2);

    -- Modüler Ters Alıcı (mod_exp kullanarak)
    U_INV: mod_exp generic map (DATA_WIDTH => WIDTH)
        port map (
            clk => clk, rst => rst, start => me_start, 
            start_value => x"00000001", 
            base => r_den, 
            exp => r_p_minus_2, 
            modulus => modulus, result => me_res, done => me_done
        );

    -- Montgomery Çarpıcı
    U_MULT: mon_pro generic map (DATA_WIDTH => WIDTH)
        port map (
            clk => clk, rst => rst, start => mp_start, 
            a_in => mp_a, b_in => mp_b, n_in => modulus, 
            result => mp_res, done => mp_done
        );

    -- Ana FSM Süreci
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE; state_num <= 0; done <= '0'; 
            me_start <= '0'; mp_start <= '0';
            res_x <= (others => '0'); res_y <= (others => '0');
        elsif rising_edge(clk) then
            
            -- State to Integer Mapping (Debug için)
            case state is
                when IDLE          => state_num <= 0;
                when PREP_DOUBLE_1 => state_num <= 1;
                when START_INV     => state_num <= 2;
                when WAIT_INV      => state_num <= 3;
                when START_LAMBDA  => state_num <= 4;
                when WAIT_LAMBDA   => state_num <= 5;
                when START_X3_SQ   => state_num <= 6;
                when WAIT_X3_SQ    => state_num <= 7;
                when CALC_X3       => state_num <= 8;
                when START_Y3_MULT => state_num <= 9;
                when WAIT_Y3_MULT  => state_num <= 10;
                when FINISH        => state_num <= 11;
                when others        => state_num <= 15;
            end case;

            case state is
                
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        -- P1 = P2 ise Katlama (Doubling), değilse Toplama (Addition)
                        if (p1_x = p2_x) and (p1_y = p2_y) then
                            is_doubling <= '1';
                            -- Doubling Pay: 3x^2 + a için önce x^2 hesapla
                            mp_a <= p1_x; mp_b <= p1_x; mp_start <= '1';
                            state <= PREP_DOUBLE_1;
                        else
                            is_doubling <= '0';
                            -- Addition Pay/Payda: (y2-y1) ve (x2-x1)
                            r_num <= mod_sub(unsigned(p2_y), unsigned(p1_y), unsigned(modulus));
                            r_den <= mod_sub(unsigned(p2_x), unsigned(p1_x), unsigned(modulus));
                            state <= START_INV;
                        end if;
                    end if;

                when PREP_DOUBLE_1 =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        -- r_num = 3x^2 + a
                        r_num <= mod_add(unsigned(mod_add(unsigned(mp_res), unsigned(mp_res), unsigned(modulus))), 
                                         unsigned(mod_add(unsigned(mp_res), unsigned(a_param), unsigned(modulus))), unsigned(modulus));
                        -- r_den = 2y
                        r_den <= mod_add(unsigned(p1_y), unsigned(p1_y), unsigned(modulus));
                        state <= START_INV;
                    end if;

                when START_INV =>
                    me_start <= '1';
                    state <= WAIT_INV;

                when WAIT_INV =>
                    me_start <= '0';
                    if me_done = '1' then state <= START_LAMBDA; end if;

                when START_LAMBDA =>
                    mp_a <= r_num; mp_b <= me_res; mp_start <= '1';
                    state <= WAIT_LAMBDA;

                when WAIT_LAMBDA =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        r_lambda <= mp_res; state <= START_X3_SQ;
                    end if;

                when START_X3_SQ =>
                    mp_a <= r_lambda; mp_b <= r_lambda; mp_start <= '1';
                    state <= WAIT_X3_SQ;

                when WAIT_X3_SQ =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        -- x3 = lambda^2 - x1
                        r_x3 <= mod_sub(unsigned(mp_res), unsigned(p1_x), unsigned(modulus));
                        state <= CALC_X3;
                    end if;

                when CALC_X3 =>
                    if is_doubling = '1' then
                        -- x3 = lambda^2 - 2*x1
                        res_x <= mod_sub(unsigned(r_x3), unsigned(p1_x), unsigned(modulus));
                        r_x3  <= mod_sub(unsigned(r_x3), unsigned(p1_x), unsigned(modulus));
                    else
                        -- x3 = lambda^2 - x1 - x2
                        res_x <= mod_sub(unsigned(r_x3), unsigned(p2_x), unsigned(modulus));
                        r_x3  <= mod_sub(unsigned(r_x3), unsigned(p2_x), unsigned(modulus));
                    end if;
                    state <= START_Y3_MULT;

                when START_Y3_MULT =>
                    mp_a <= r_lambda;
                    mp_b <= mod_sub(unsigned(p1_x), unsigned(r_x3), unsigned(modulus));
                    mp_start <= '1';
                    state <= WAIT_Y3_MULT;

                when WAIT_Y3_MULT =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        -- y3 = lambda(x1 - x3) - y1
                        res_y <= mod_sub(unsigned(mp_res), unsigned(p1_y), unsigned(modulus));
                        state <= FINISH;
                    end if;

                when FINISH =>
                    done <= '1'; state <= IDLE;

                when others => state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;