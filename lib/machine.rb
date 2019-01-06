module Archlinux
  class Machine
    class << self
      def is_virtual_box?
        `lspci | grep VirtualBox`
        $?.to_i == 0
      end
      
      def has_gforce_video_card?
        has_video_card_from? '[Nn][Vv][Ii][Dd][Ii][Aa]'
      end
      
      def has_intel_video_card?
        has_video_card_from? '[Ii]ntel'
      end
      
      def has_ati_video_card?
        has_video_card_from? '[Rr]adeon|ATI|AMD'
      end
      
    private
      def has_video_card_from? manufacturer
        `lspci -nn | egrep "VGA|Display" | egrep "#{manufacturer}"`
        $?.to_i == 0
      end
    end
  end
end