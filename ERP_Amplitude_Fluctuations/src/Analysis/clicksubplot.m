function selected = clicksubplot()

selected = {};

while 1
    w = waitforbuttonpress;

    switch w 
      case 1 % keyboard 
          key = get(gcf,'currentcharacter'); 
          if key == 27 % (the Esc key) 
              break
          end

      case 0 % mouse click 
          mousept = get(gcf,'SelectionType');
          if strcmp(mousept, 'normal')
              selected = {selected{:} get(gca,'tag')};
              set(gca,'color','green');
          elseif strcmp(mousept, 'open')
              selected(strcmp(get(gca,'tag'), selected)) = [];
              set(gca,'color','white');
          end
    end
end

end