/*
 * mspacman.prg by Mike
 * (c) 2023 LUL
 */

PROGRAM mspacman;
CONST

greenpath = 39;
redpath = 22;
bluepath = 54;
global

ghost_colours[] = (165,254, 200,121);
framecount =0;
playing = 0;


BEGIN

//Write your code here, make something amazing!
set_mode(m320x240);
load_fpg("mspacman.FPG");

//put_screen(file, 200);
maze();
player();
from x = 1 to 4;
ghost(x);

end

//graph = 101 ;
//x=160;
//y=97;
//flags = 4;


while(!key(_space))
frame(1000);
framecount++;
end

playing = 1;


loop

framecount++;
frame(1000);

end



END

process maze()

private
px;
py;

begin

x=1;
repeat
    get_point(file,102,x, &px, &py);
    //debug;

    if (px < 65000 && px > 0 && py > 0)
        wafer(px+4,py+13);
        wafer((320-px)-4, py+13);

    else
      break;
    end
    x++;

until (x==100);

/*
FROM x = 9 to 134;
    get_point(file,101,x,&px, &py);
    wafer(px,py);
    break;
END

// setup powerpills
FROM x = 1 to 4;
    get_point(file,101,x,&px,&py);
    powerpill(px,py);
end
*/

/*
repeat

until x = 0
*/
graph = 102 ;
x=160;
y=97;
//flags = 4;



loop;
frame;
end


end

process wafer(x,y)

begin

graph = 50;


while(!collision(type player))
frame;
end

end


process ghost(gid)

private
pal[256];
wait = 0;
speed = 4;
dx = -1;
dy = 0;
nx = 0;
ny = 0 ;
ox;
oy;
p;
dir = 0;
odir = 0;
flen = 0;
tid;
fc = 0;
begin

graph = new_map(16,10,8,5,0);
map_put(file,graph,10,8,5);
from x = 0 to 255;
pal[x] = x;
end

pal[135] = ghost_colours[gid-1];

convert_palette(file, graph, &pal);


x= 160;
if (gid == 1)
y = 67;
else
y = 98;
dx = speed;
wait = gid * 60;
//odir = 1;
//dir = 1;
dir = 2;
odir = 2;

end

flen = 100 + (gid-1) * 8;

//write_int(0,0,4+gid*12,0,offset reserved.frame_percent);

//flags = 4;
loop
    //delete_text(tid);

    //tid = write(0,20,20,4,itoa(reserved[0].frame_percent));

        //debug;
    if(playing)
    if (wait > 0) wait --; end

    p = map_get_pixel(file,101,x-1,y-13);
    map_put_pixel(file,100,x-1,y-13,redpath);
    odir = dir;
    ox = x;
    oy = y;

    if (p != bluepath)
        x+=dx;
        y+=dy;
        if (x<-16) x=336; end
        if (x> 336) x=-16; end

    else
    /*
    if ( y == 98)
        debug;
    end
    */
    dir = rand(0,3);
    repeat
        x = ox;
        y = oy;

        repeat
            dir++;
            dir = dir mod 4;


        until ((odir &1) != (dir &1) or odir == dir)

        switch(dir)
            case 0: // left
                nx = -1;
                ny = 0;
                speed = 4;
            end

            case 1:  // up
                nx = 0;
                ny = -1;
                speed = 2;
            end

            case 2:  // right
                nx = 1;
                ny = 0;
                speed = 4;

            end

            case 3:  // down
                nx = 0;
                ny = 1;
                speed = 2;
            end
        end

        x+=nx;
        y+=ny;
        p = map_get_pixel(file,101,x-1,y-13);

     until (p == redpath or (oy == 98 && p == greenpath && wait == 0));

     dx = nx;
     dy = ny;

     end

    end

    if(fc < framecount)
        fc = framecount;
        flags = 1 - flags;
    end

    frame(flen/speed);
    //debug;
end

end



process player()

private
anim=0;
anims[] = (0,1,2,1);
dirs[] = (1,4,1,4);
mflags[] = (0,0,3,1);
dir = 1;
tid;
i;
ox;
oy;
odir;
dx;
dy;
nx;
ny;

begin

x=160;
y=115;

//delete_text(tid);

loop
    anim++;
    // get the current pixel under the player
    if(anim == 4)
        anim = 0;
    end

    odir = dir;

    if(key(_up))
        dir = 2;
    end

    if(key(_down))
        dir = 0;
    end

    if(key(_left))
        dir = 1;
    end

    if(key(_right))
        dir = 3;
    end

    if(playing)

    switch(dir)
        case 0:
            nx = 0;
            ny =2;
        end

        case 1:
            nx = -4;
            ny = 0;
        end

        case 2:
            ny = -2;
            nx = 0;
        end

        case 3:
            nx = 4;
            ny = 0;
        end

    end


    i = map_get_pixel(file,101,x+nx-1,y+ny-13);

    if( i == 0 || i == greenpath)
       nx = 0;
       ny = 0;
       dir = odir;
    else
        dx = nx;
        dy = ny;
        odir = dir;
    end
    ox = x;
    oy = y;
    x+=dx;
    y+=dy;

    i = map_get_pixel(file,101,x-1,y-13);

    if(i == 0 or i == greenpath)
        x = ox;
        y = oy;
        dx= 0;
        dy = 0;
    end

    end

    graph = dirs[dir]+anims[anim];
    flags = mflags[dir];
    //map_put_pixel(file,100,x,y-13,1);
    //write_int(0,0,4,0,offset i);
    frame;

end


end
