/*
 * mspacman.prg by Mike
 * (c) 2023 LUL
 */

PROGRAM mspacman;
CONST

greenpath = 32;
redpath = 166;
bluepath = 98;

DIR_LEFT = 0;
DIR_UP = 1;
DIR_RIGHT = 2;
DIR_DOWN = 3;

M_SCATTER = 0;
M_HUNT = 1;
M_SCARED = 2;


global

ghost_colours[] = (
170, // red ghost
241, // pink ghost
86, // blue ghost
154  // yellow ghost
);
ghost_ids[4];
struct ghost_home[4]
    x;
    y;
end = (
    312,14,
    9,14,
    312,178,
    9,178
    );

framecount =0;
playing = 0;


local
dangle;

BEGIN

//Write your code here, make something amazing!
set_mode(m320x240);
load_fpg("mspacman.FPG");

//put_screen(file, 200);
maze();
player();
from x = 0 to 3;
ghost_ids[x] = ghost(x);

end

/*
graph = 101 ;
x=160;
y=97;
flags = 4;
*/

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
priority = 1;


loop;
delete_draw(all_drawing);

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
mode;
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
dir = 1;
odir = 1;
flen = 0;
tid;
fc = 0;
target;
tx = 0;
ty = 0;
v = false;
tries = 5;
dirs[4];
num_points;
index;

struct points[100];
x;
y;

end

begin
mode = M_HUNT;

graph = new_map(16,10,8,5,0);
map_put(file,graph,10,8,5);
from x = 0 to 255;
pal[x] = x;
end

pal[171] = ghost_colours[gid];

convert_palette(file, graph, &pal);


x= 160;
if (gid == 0)
    y = 67;
    dir = DIR_LEFT;
    dx = -1;
else
    y = 98;
    dx = 1;
    wait = gid * 200;
    //odir = 1;
    ///dir = 1;
    dir = DIR_RIGHT;

end
//flags = 4;

flen = 90 + (gid * 8);

//write_int(0,0,4+gid*12,0,offset reserved.frame_percent);

//flags = 4;

target = get_id(type player);


loop
    //delete_text(tid);

    //tid = write(0,20,20,4,itoa(reserved[0].frame_percent));

        //debug;
    if(playing)

        if (wait > 0)
            wait --;
            //size = 50;

        else

            //size = 100;

        end

        p = map_get_pixel(file,101,x-1,y-13);
        //map_put_pixel(file,100,x-1,y-13,redpath);
        odir = dir;

        // if we arent on a bluepath to change direction, just kep going.
        if (p != bluepath)
            x+=dx;
            y+=dy;

            // and go through maze exits
            if (x<-16)
                x=336;
            end

            if (x> 336)
                x=-16;
            end

        else

            // blue path.. make some decisions
            tx = target.x;
            ty = target.y;


            if ( mode == M_HUNT)

            switch(gid)
                // red ghost
                case 0:

                    // target is exactly where mspacman is
                    // so do nothing
                end


                case 1:
                    // target is 4 whole units ahead of mspacman
                    if (target.dangle == -90000 or target.dangle == 90000)

                        if(target.dangle == -90000)
                            ty = target.y + 32;
                        else
                            ty = target.y - 32;
                            tx = target.x - 64;  // if its up, we also go 4 to the left
                        end

                    else
                        if(target.dangle == -180000)
                            tx = target.x - 64;
                        else
                            tx = target.x + 64;
                        end
                    end

                end

                case 2:
                    // target is the space that is double the distance from
                    // red ghost to two spaces ahead of mspacman

                    if (target.dangle == -90000 or target.dangle == 90000)

                        if(target.dangle == -90000)
                            ty = target.y + 16;
                        else
                            ty = target.y - 16;
                            tx = target.x - 32; // same case here, 2 up 2 left
                        end

                    else
                        if(target.dangle == -180000)
                            tx = target.x - 16;
                        else
                            tx = target.x + 32;
                        end
                    end

                    // tx acquired.. now calculate from red ghost's x

                    // get the distance between the two points.

                    p = fget_dist(ghost_ids[0].x, ghost_ids[0].y,tx,ty)*2;
                    dangle = fget_angle(ghost_ids[0].x, ghost_ids[0].y,tx,ty);
                    ox = x;
                    oy = y;
                    x = ghost_ids[0].x;
                    y = ghost_ids[0].y;


                    xadvance(dangle, p);

                    tx = x;
                    ty = y;
                    x = ox;
                    y = oy;
                end

                case 3:
                   p = get_dist(target);
                   if (p < 64)

                    tx = ghost_home[gid].x;
                    ty = ghost_home[gid].y;

                   else
                     // redundant
                    tx = target.x;
                    ty = target.y;
                   end
                end

            end
            else
                tx = ghost_home[gid].x;
                ty = ghost_home[gid].y;
            end






            //if ( y == 98)
            //    debug;
            //end
            odir = dir;

            ox = x;
            oy = y;

            //dir = rand(0,3);
            v = false;
            tries = 5;

            from p = 0 to 3;
                dirs[p] = 0;
                nx = x;
                ny = y;
                switch(p)
                    case DIR_LEFT:
                        nx--;
                    end


                    case DIR_UP:
                        ny--;
                    end

                    case DIR_RIGHT:
                        nx++;
                    end

                    case DIR_DOWN:
                        ny++;
                    end
                end

                if(map_get_pixel(file,101,nx-1,ny-13) == 0)
                    dirs[p]=1;
                end
            end

            p = (dir + 2) mod 4;

            dirs[p] = 2;

            //debug;
            //p = 2 - (dir & 1)  + (dir & 1);

            //dirs[p] = 1;



            repeat
                dir = -1;
                x--;
                y-=13;
                num_points = path_find(1, file, 103,2,tx-1,ty-13, &points, sizeof(points));
                x++;
                y+=13;
                //num_points=path_find(0,0,201,2,mouse.x,mouse.y,OFFSET points,sizeof(points));

        // If a route was obtained, it shows the route and advances to the destination

        /*
        IF (num_points>0)
            tx = points[0].x+1;
            ty = points[0].y+13;

            FOR (index=0;index<num_points-1;index++)
                draw(1,24,15,0,points[index].x+1,points[index].y+13,points[index+1].x+1,points[index+1].y+13);
            END

//            IF (fget_dist(x,y,points[0].x,points[0].y)>4)
//                xadvance(fget_angle(x,y,points[0].x,points[0].y),4);
//            ELSE
//                x=points[0].x;
//                y=points[0].y;
//            END

            draw(1,24,15,0,x,y,points[0].x+1,points[0].y+13);

        END
        */

        if ( abs(tx - x) > abs(ty - y))
            ty = y;
        else
            tx = x;
        end

        dangle = MAX_INT;
        from p = 0 to 3;
            if (dirs[p] == 0)
            switch(p)

                case DIR_LEFT:
                    v = fget_dist(x-1,y,tx,ty);
                    if (v < dangle)
                        dir = DIR_LEFT;
                        dangle = v;
                    end
                end

                case DIR_RIGHT:
                    v = fget_dist(x+1,y,tx,ty);
                    if (v < dangle)
                        dir = DIR_RIGHT;
                        dangle = v;
                    end
                end

                case DIR_UP:
                    v = fget_dist(x,y-1,tx,ty);
                    if (v < dangle)
                        dir = DIR_UP;
                        dangle = v;
                    end
                end

                case DIR_DOWN:
                    v = fget_dist(x,y+1,tx,ty);
                    if (v < dangle)
                        dir = DIR_DOWN;
                        dangle = v;
                    end
                end

            end
            end

       end

                if (dir == -1)
                    dir = odir;
                end

                if (dirs[dir] != 0)
                    from p = 0 to 3;
                        if (dirs[p] == 0)
                            dir = p;
                            //debug;

                            break;
                        end
                    end
                end

                if (dir <0 or dir > 3 )
                    dir = odir;
                end


                dirs[dir] = 1;

                x = ox;
                y = oy;



            //if ( ((odir &1) != (dir &1)) or dir == odir )

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


            //if ((abs(nx) != abs(dx)) or odir == dir)
            //if (true)
                x+=nx;
                y+=ny;

  //              map_put_pixel(file,102,x-1,y-13,greenpath);

               p = map_get_pixel(file,101,x-1,y-13);
               //if (p == greenpath and ox == 98)

               /*
                if (p == 0) // or ( p!=98 and p == greenpath) or ( odir &1 == dir &1))


                    dir ++;

                    if (dir == 4)
                        dir = 0;
                    end
                    x = ox;
                    y = oy;

                    ///dir = dir mod 4;
                //end
                else
                    v = true;
                    tries = 0;
                end

                //if (p == redpath or (oy == 98 && p == greenpath && wait == 0))
                //   v = true;

                   //break;
                //else
                    //debug;
                //end

            //else
            //    dir ++;
            //    dir = dir mod 4;
            //end
            */
            //tries--;
            until (tries <= 0 or p == redpath or (p == greenpath and oy == 98 and wait == 0) or v == true)


            dx = nx;
            dy = ny;

        end

    end

    if(fc < framecount)
        fc = framecount;
        flags = 1 - flags;
    end
    //x=tx;
    //y=ty;

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
odangle;

begin

x=160;
y=115;
dangle = 90000;
//delete_text(tid);

loop
    if ( x!=ox or y!=oy or playing == false)
        anim++;
        // get the current pixel under the player
        if(anim == 4)
            anim = 0;
        end
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
    odangle = dangle;
    if(playing)

    switch(dir)
        case 0:
            nx = 0;
            ny =2;
            dangle = -90000;
        end

        case 1:
            nx = -4;
            ny = 0;
            dangle = -180000;
        end

        case 2:
            ny = -2;
            nx = 0;
            dangle = 90000;
        end

        case 3:
            nx = 4;
            ny = 0;
            dangle = 180000;
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
            // and go through maze exits
            if (x<-16)
                x=336;
            end

            if (x> 336)
                x=-16;
            end

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
