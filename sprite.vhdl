--
-- Written by
--    Paul Gardner-Stephen <hld@c64.org>  2014
--
-- *  This program is free software; you can redistribute it and/or modify
-- *  it under the terms of the GNU Lesser General Public License as
-- *  published by the Free Software Foundation; either version 3 of the
-- *  License, or (at your option) any later version.
-- *
-- *  This program is distributed in the hope that it will be useful,
-- *  but WITHOUT ANY WARRANTY; without even the implied warranty of
-- *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- *  GNU General Public License for more details.
-- *
-- *  You should have received a copy of the GNU Lesser General Public License
-- *  along with this program; if not, write to the Free Software
-- *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
-- *  02111-1307  USA.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use Std.TextIO.all;
use work.debugtools.all;
use work.cputypes.all;

entity sprite is
  Port (
    ----------------------------------------------------------------------
    -- dot clock
    ----------------------------------------------------------------------
    pixelclock : in  STD_LOGIC;

    signal sprite_number : in integer range 0 to 7;

    -- Pull sprite data in along the chain from the previous sprite (or VIC-IV)
    signal sprite_datavalid_in : in std_logic;
    signal sprite_bytenumber_in : in integer range 0 to 2;
    signal sprite_spritenumber_in : in integer range 0 to 7;
    signal sprite_data_in : in unsigned(7 downto 0);

    -- Pass sprite data out along the chain to the next sprite
    signal sprite_datavalid_out : out std_logic;
    signal sprite_bytenumber_out : out integer range 0 to 2;
    signal sprite_spritenumber_out : out integer range 0 to 7;
    signal sprite_data_out : out unsigned(7 downto 0);

    -- which base offset for the VIC-II sprite data are we showing this raster line?
    -- VIC-IV clocks sprite_number_for_data and each sprite replaces
    -- sprite_data_offset with the appropriate value if the sprite number is itself
    signal sprite_number_for_data_in : in integer range 0 to 7;
    signal sprite_data_offset_in : in integer range 0 to 1023;    
    signal sprite_data_offset_out : out integer range 0 to 1023;    
    signal sprite_number_for_data_out : out integer range 0 to 7;
    
    -- Is the pixel just passed in a foreground pixel?
    signal is_foreground_in : in std_logic;
    -- and what is the colour of the bitmap pixel?
    signal x_in : in integer range 0 to 4095;
    signal y_in : in integer range 0 to 4095;
    signal border_in : in std_logic;
    signal pixel_in : in unsigned(7 downto 0);
    -- and information from the previous sprite
    signal is_sprite_in : in std_logic;
    signal sprite_colour_in : in unsigned(7 downto 0);

    -- Pass pixel information back out, as well as the sprite colour information
    signal is_foreground_out : out std_logic;
    signal x_out : out integer range 0 to 4095;
    signal y_out : out integer range 0 to 4095;
    signal border_out : out std_logic;
    signal pixel_out : out unsigned(7 downto 0);
    signal sprite_colour_out : out unsigned(7 downto 0);
    signal is_sprite_out : out std_logic;

    signal sprite_enable : in std_logic;
    signal sprite_x : in unsigned(8 downto 0);
    signal sprite_y : in unsigned(7 downto 0);
    signal sprite_colour : in unsigned(7 downto 0);
    signal sprite_multi0_colour : in unsigned(7 downto 0);
    signal sprite_multi1_colour : in unsigned(7 downto 0);
    signal sprite_is_multicolour : in std_logic;
    signal sprite_stretch_x : in std_logic;
    signal sprite_stretch_y : in std_logic;
    signal sprite_priority : in std_logic

);

end sprite;

architecture behavioural of sprite is

  signal sprite_data_offset : integer range 0 to 1023;    
  signal y_last : integer range 0 to 4095;
  signal x_last : integer range 0 to 4095;
  signal x_left : std_logic := '0';
  signal y_top : std_logic := '0';
  signal sprite_drawing : std_logic := '0';
  signal y_offset : integer range 0 to 21;
  signal x_offset : integer range 0 to 24;
  signal x_expand_toggle : std_logic := '0';
  signal y_expand_toggle : std_logic := '0';
  
begin  -- behavioural
  
  -- purpose: sprite drawing
  -- type   : sequential
  -- inputs : pixelclock, <reset>
  -- outputs: colour, is_sprite_out
  main: process (pixelclock)
  begin  -- process main
    if pixelclock'event and pixelclock = '1' then  -- rising clock edge
--      report "SPRITE: entering VIC-II sprite #" & integer'image(sprite_number);
      -- copy sprite data chain from input side to output side      
      sprite_datavalid_out <= sprite_datavalid_in;
      sprite_bytenumber_out <= sprite_bytenumber_in;
      sprite_data_out <= sprite_data_in;
      sprite_number_for_data_out <= sprite_number_for_data_in;

      if sprite_number_for_data_in = sprite_number then
        -- Tell VIC-IV our current sprite data offset
        sprite_data_offset_out <= sprite_data_offset;
      else
        sprite_data_offset_out <= sprite_data_offset_in;
      end if;

      -- copy pixel data chain from input side to output side

      pixel_out <= pixel_in;
      x_out <= x_in;
      y_out <= y_in;
      border_out <= border_in;
      is_foreground_out <= is_foreground_in;

      -- Work out when we start drawing the sprite
      y_last <= y_in;
      x_left <= '0';
      y_top <= '0';
      -- sprite data offset = y_offset * 3
      sprite_data_offset <= (y_offset * 2) + y_offset;
      if y_in = sprite_y then
        y_top <= '1';
        y_offset <= 0;
        y_expand_toggle <= '0';
      end if;
      if x_in = sprite_x then
        x_left <= '1';
        x_offset <= 0;
      end if;
      if x_left = '1' and y_top = '1' then
        sprite_drawing <= '1';
      end if;
      -- Advance Y position of sprite
      if y_last /= y_in and sprite_drawing = '1' then
        -- Y position has advanced while drawing a sprite
        if y_expand_toggle = '1' or sprite_stretch_y='0' then
        end if;
      end if;

      
      
      -- decide whether we are visible or not, and update sprite colour
      -- accordingly.
      -- XXX - for now just copy input to output
      is_sprite_out <= is_sprite_in;
      sprite_colour_out <= sprite_colour_in;

--      report "SPRITE: leaving VIC-II sprite #" & integer'image(sprite_number);
    end if;
  end process main;

end behavioural;
