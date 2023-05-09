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
M_EYES = 3;

global

pal[256];

level = 2;
map_base;
path_map;
hard_map;
point_map;

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
scared;

BEGIN

map_base = 100 + level * 4;
point_map = map_base + 2;
hard_map = map_base + 1;
path_map = map_base + 3;

//Write your code here, make something amazing!
set_mode(m320x240);
load_fpg("mspacman.FPG");

// draw maze
maze();

// spawn player
player();

// spawn ghosts
from x = 0 to 3;
    ghost_ids[x] = ghost(x);
end


// wait for space to be pressed to start the game

while(!key(_space))
    frame(1000);
    framecount++;
end

// now playing
playing = 1;


// main loop
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

// spawn wafers
repeat
    // get a point on the map
    get_point(file,point_map,x, &px, &py);

    // check if it is a valid wafer location
    if (px < 65000 && px > 0 && py > 0)

        // spawn wafer (left side)
        wafer(px+4,py+13);

        // and right side)
        wafer((320-px)-4, py+13);

    else
        // value out of range, wafers complete
        break;
    end
    x++;

until (x==100);  // or max reached

// spawn power pills
x=100;
repeat
    // get a point on the map
    get_point(file,point_map,x, &px, &py);

    // check if it is a valid power pill location
    if (px < 65000 && px > 0 && py > 0)

        // draw on left
        pill(px+4, py+16);

        // and right
        pill((320-px)-4, py+16);


    else
        // value out of range, pills complete
        break;
    end
    x++;

until (x==102); // or max reached


// our map graph
graph = point_map ;

// location on screen
x=160;
y=97;

// execute this process before others
priority = 1;


loop

    // if f key pressed
    if (key(_f))

        // spawn cherries
        fruit();

        // wait until f no longer pressed
        while(key(_f))
            frame();
        end

    end

    frame;

end


end

// wafer process
process wafer(x,y)

private

pid;

begin

// wafer graphic
graph = 50;

// Create a copy of the palette
from pid = 0 to 255;
    pal[pid] = pid;
end

// set palette id 171 (colour of the template ghost) to our ghost colour
pal[map_get_pixel(file,graph,0,0)] = map_get_pixel(file,map_base,0,0);

// convert our ghost sprite to use this palette
convert_palette(file, graph, &pal);


loop
    pid = collision(type player);

    // did we collide with player?
    if(pid)

        // close enough?
        if(pid.y == y)
            if(abs(pid.x-x)<4)
                return;
            end
        else
            if(abs(pid.y-y)<2)
                return;
            end
        end

    end


    frame;
end

end


// power pill process
process pill(x,y)

private

pid;

begin

// power pill graphic
graph = 51;

// Create a copy of the palette
from pid = 0 to 255;
    pal[pid] = pid;
end

// set palette id 171 (colour of the template ghost) to our ghost colour
pal[map_get_pixel(file,graph,0,0)] = map_get_pixel(file,map_base,0,0);

// convert our ghost sprite to use this palette
convert_palette(file, graph, &pal);


loop
    // alternate on / off
    size = 100-size;

    // get player process id
    pid = collision(type player);

    // did we collide with player?
    if(pid)

        // iterate over ghosts and make them "scared"
        repeat
            pid = get_id(type ghost);
            if(pid)
                pid.scared = 1;
            end
        until (pid == 0);

        return;
    end

    // flash delay
    frame(400);
end

end



// ghost process
// -------------
//
// This is a lot of code due to the way the ghosts
// AI and movement is calculated.
//
// I have tried to explain the code as best as possible

process ghost(gid)

private
mode;
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

// sane default
flen = 100;
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
scaredtime = 0;
ograph = 0;
egraph;

// storage for path finder
struct points[100];
    x;
    y;
end


// entry point
begin

// start in "hunt" mode
mode = M_HUNT;

// create a blank map for our ghost
ograph = new_map(16,10,8,5,0);

// set our graph to the new map
graph = ograph;

// paste the template ghost sprite from the FPG at id 10
map_put(file,graph,10,8,5);

// create a blank map for our "eyes"
egraph = new_map(16,10,8,5,0);

// paste the template ghost eyes sprite from the FPG at id 12
map_put(file,egraph,12,8,5);


// Create a copy of the palette
from x = 0 to 255;
    pal[x] = x;
end

// set palette id 171 (colour of the template ghost) to our ghost colour
pal[171] = ghost_colours[gid];

// convert our ghost sprite to use this palette
convert_palette(file, graph, &pal);

// and the eyes
convert_palette(file, egraph, &pal);


// starting x position is centre of screen
x= 160;

// if we are the red ghost
if (gid == 0)

    // start outside the home
    y = 67;

    // and go left?
    dir = DIR_LEFT;

    // and x direction is minus 1 (go left)
    dx = -1;
else

    // a ghost starting in the home
    y = 98;


    // delay until they can escape
    wait = (gid-1) * 100;

    // go right
    dir = DIR_RIGHT;

    // x direction is plus 1 (go right)
    dx = 1;

end




// the target process for AI calculations
target = get_id(type player);


// main loop
loop

    // has the scared flag been set?
    if (scared == 1)
        // unset it
        scared = 0;

        // if not already eyes
        if (mode != M_EYES)
            // set mode to M_SCARED
            mode =  M_SCARED;

            // and the scared graphic
            graph = 11;

            // and set how long we will be scared for
            scaredtime = 20;

            // change direction
            // 0 = 2, 1 = 3, 2 = 0, 3 = 1...
            dir = (dir + 2) mod 4;

            // and invert directional vector
            dx = -dx;
            dy = -dy;

            // and go slow

            flen = 150;
        end
    end


    // if game in progress
    if(playing)

        // are we waiting in the home?
        if (wait > 0)

            // decrease wait time
            wait --;

        end

        // set our ghost speed based upon what state we are in
        // frame length modifies speed of the ghost
        // bigger flen = slower ghost
        //
        // on ghost movement...
        // flen = 100 + (gid * 8);

        switch(mode)
            case M_HUNT:
                flen = 100 + (gid * 8);
            end

            case M_SCATTER:
                flen = 100 + (gid * 8);
            end

            case M_SCARED:
                flen = 200;
            end


            case M_EYES:
                flen = 75;
            end
        end



        // get the pixel of the hardness map under our ghost
        p = map_get_pixel(file,hard_map,x-1,y-13);

        // save the original direction value
        odir = dir;

        // if we arent on a bluepath to change direction, just keep going.
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


            // by default, target player coordinates


            // what state are we in?
            switch(mode)

                // hunt mode - target player directly.
                case M_HUNT:

                    switch(gid)
                        // red ghost
                        case 0:

                            // target is exactly where mspacman is
                            	tx = target.x;
                            ty = target.y;

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

                            // How far are we from the target?
                            p = get_dist(target);

                            // close to the target?
                            if (p < 64)
                                // return to home "corner"
                                tx = ghost_home[gid].x;
                                ty = ghost_home[gid].y;

                            else
                                // head straight for target
                                tx = target.x;
                                ty = target.y;
                            end
                        end

                    end // end ghost switch

                end // end M_HUNT


                // if scared or scatter, return to "home" corner
                case M_SCATTER:
                    tx = ghost_home[gid].x;
                    ty = ghost_home[gid].y;
                end

                case M_SCARED:
                    tx = ghost_home[gid].x;
                    ty = ghost_home[gid].y;

                end

                // if eyes, return to base
                case M_EYES:
                    tx = 160;
                    ty = 84;
                end
            end


            // calculate which direction we want to proceed in.


            // save old direction
            odir = dir;

            // and old coordinates
            ox = x;
            oy = y;

            // set v to false (invalid direction) and tries to 5 for max attemps.
            v = false;
            tries = 5;

            // examine each direction and discover if it is valid to
            // moe that way.
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

                if(map_get_pixel(file,hard_map,nx-1,ny-13) == 0)
                    dirs[p]=1;
                end
            end


            // mark "reverse" as invalid
            p = (dir + 2) mod 4;
            dirs[p] = 2;

            // if we are eyes...
            if (mode == M_EYES)
                // have we reached the reincarnation chamber?
                if (x == tx and y == ty)

                    // reset chase mode
                    mode = M_HUNT;

                    // and ghost graphic
                    graph = ograph;

                    // only go left inside box
                    from p = 0 to 3;
                        dirs[p] = 1;
                    end
                    // ensure we have "left" as a valid direction for choices.
                    dirs[DIR_LEFT] = 0;
                end
            end

            // repeat the following until we have a valid direction.
            repeat

                // dir is invalid
                dir = -1;

                // use the path map to see the points in the path from us to the target x/y

                // use the x/y offset
                x--;
                y-=13;
                num_points = path_find(1, file, path_map,2,tx-1,ty-13, &points, sizeof(points));

                // and put x/y back
                x++;
                y+=13;

                // If a route was obtained, it shows the route and advances to the destination
                IF (num_points>0)

                    // target is the first point in the path find
                    tx = points[0].x+1;
                    ty = points[0].y+13;


                    // debug draw path

                    /*
                    FOR (index=0;index<num_points-1;index++)
                        draw(1,24,15,0,points[index].x+1,points[index].y+13,points[index+1].x+1,points[index+1].y+13);
                    END


                    draw(1,24,15,0,x,y,points[0].x+1,points[0].y+13);
                    */
                END


                // whichever is closer, try to move that way.
                if ( abs(tx - x) > abs(ty - y))
                    ty = y;
                else
                    tx = x;
                end


                // temporary value
                dangle = MAX_INT;

                // check all directions for best
                from p = 0 to 3;

                    // is this direction allowed?
                    if (dirs[p] == 0)
                        switch(p)

                        case DIR_LEFT:
                            // how far are we from the target?
                            v = fget_dist(x-1,y,tx,ty);

                            // shorter than previous best?
                            if (v < dangle)
                                // set direction
                                dir = DIR_LEFT;
                                // and "best" option
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

                    end // direction invalid
                end // loop

            end

            // new valid direction found?
            if (dir == -1)
                // just carry on in old direction
                dir = odir;
            end

            // if previous direction was invalid
            if (dirs[dir] != 0)
                // find the next valid one
                from p = 0 to 3;
                    if (dirs[p] == 0)
                        dir = p;
                        break;
                    end
                end
            end

            // impossible?
            if (dir <0 or dir > 3 )
                dir = odir;
            end


            // mark used direction as "tried"
            dirs[dir] = 1;

            // and put x/y back to what they were
            x = ox;
            y = oy;



            // which way should we go?
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

            // move the ghost
            x+=nx;
            y+=ny;

            // get the pixel under our new position
            p = map_get_pixel(file,hard_map,x-1,y-13);

            // check if this is a valid location, and if not, go try another one.
            until (tries <= 0 or p == redpath
                or (p == greenpath and oy == 84 and wait == 0)
                or (p == greenpath and mode == M_EYES)
                or v == true)

            // new direction vector set
            dx = nx;
            dy = ny;

        end

    end

    // has framceount updated?
    if(fc < framecount)
        fc = framecount;

        // are ghosts running away?
        if (mode == M_SCARED)

            // less than 10 ticks left
            if (scaredtime < 10)
                // no flip
                flags = 0;

                // alt white/blue
                if (graph == 11)
                    graph = 13;
                else
                    graph = 11;
                end
            else
                // alt-flip
                flags = 1 - flags;
            end


        else
            // alt-flip (regular ghost)
            if (mode != M_EYES)
                flags = 1 - flags;
            end
        end

        // any scared time left?
        if(scaredtime > 0)

            // reduce it
            scaredtime --;

            // all done?
            if(scaredtime == 0)

                // return to regular ghost
                graph = ograph;

                // and chase player
                mode = M_HUNT;

            end
        end


    end

    // are we running away?
    if (mode == M_SCARED);

        // check collision with player
        p = collision(type player);

        // collision detected?
        if(p)

            // same y axis?
            if(p.y == y)

                // and less than 16 pixels apart on x axis
                if(abs(p.x-x)<6)
                    // eaten, turn to eyes
                    mode = M_EYES;
                end
            else

                // and less than 3 pixels on y axis?
                if(abs(p.y-y)<3)

                    // eaten - turn to eyes
                    mode = M_EYES;
                end
            end


            // did we get turned into eyes?
            if (mode == M_EYES)

                // scared time is over
                scaredtime = 0;

                // turn to eyes graphic
                graph = egraph;

                // and pause temporarily
                playing = 0;

                // freeze player
                signal(p,s_freeze);

                // wait 10 frames;
                frame(1000);

                // unfreeze player
                signal(p,s_wakeup);

                // and resume game
                playing = 1;
            end

        end
    end

    // yield for correct speed based on "flen"
    frame(flen/speed);
end

end



process player()

private
anim=0;
anims[] = (0,1,2,1);
dirs[] = (4,1,4,1);
mflags[] = (0,3,1,0);
dir = DIR_LEFT;
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
intunnel;
begin

x=160;
y=115;
dangle = 90000;
intunnel = 0;
loop
    // did we move, or demo / intro
    if ( x!=ox or y!=oy or playing == false)

        // animate sprite
        anim++;

        // and wrap to zero
        if(anim == 4)
            anim = 0;
        end
    end

    // are we playing? In control...
    if(playing)

        // save original direction
        odir = dir;

        // check keys

        // up pressed?
        if(key(_up))
            dir = DIR_UP;
        end

        // down pressed?
        if(key(_down))

            dir = DIR_DOWN;
        end

        // left pressed?
        if(key(_left))
            dir = DIR_LEFT;
        end

        // right pressed?
        if(key(_right))
            dir = DIR_RIGHT;
        end


        // store the directional angle (used by ghost AI)
        odangle = dangle;

        // which direction do we want to head
        switch(dir)

            // up
            case DIR_DOWN:
                nx = 0;
                ny =2;
                dangle = -90000;
            end

            case DIR_LEFT:
                nx = -4;
                ny = 0;
                dangle = -180000;
            end

            case DIR_UP:
                nx = 0;
                ny = -2;
                dangle = 90000;
            end

            case DIR_RIGHT:
                nx = 4;
                ny = 0;
                dangle = 180000;
            end

        end


        // fetch the pixel from the hardness map under the player (offset by 1,13)
        i = map_get_pixel(file,hard_map,x+nx-1,y+ny-13);

        // did we try to go to a green path?
        if( i == 0 || i == greenpath)
            // invalidate new vectors
            nx = 0;
            ny = 0;

            // resume previous direction
            dir = odir;
        else
            // save x/y offset vectors
            dx = nx;
            dy = ny;

            // save new direction
            odir = dir;
        end

        // save x and y
        ox = x;
        oy = y;

        // add directional vectors to x and y
        x+=dx;
        y+=dy;


        // fetch the new pixel under the player
        i = map_get_pixel(file,hard_map,x-1,y-13);

        // if we still tried to go on a green path, or empty space..
        if(i == 0 or i == greenpath)
            // and go through maze exits (not working yet)
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

    // set our animation graphic
    graph = dirs[dir]+anims[anim];

    // and mirror if we need to
    flags = mflags[dir];

    // regular speed
    frame;

end


end


process fruit()

private
dx=1;
dy=0;
tx = 319;
py=0;
ty = 0;
yanim = 0;
yoffs[] = (
    0,0,
    -1,0,
    -1,0,
    -1,0,
    0,0,
    1,0,
    1,0,
    1,0
);

d = 0;

num_points;
index;

struct points[100];
    x;
    y;
end

begin
delete_text(all_text);

write_int(0,0,4,0,offset d);
write_int(0,0,16,0,offset x);
write_int(0,0,28,0,offset yanim);


graph = 20;
x=8;

y=0;
while (map_get_pixel(file,hard_map,x,y)!=redpath)
y++;
end

y+=13; // first point
ty = y;

x=-11;


//fruit needs to bounce
py = y;

loop

    y+=yoffs[yanim];

    yanim++;

    if(yanim>=sizeof(yoffs))
        yanim = 0;
        py = y;
    end
    x+=dx;
    y+=dy;
    d = map_get_pixel(file,hard_map,x-1,py-13);
    map_put_pixel(file,point_map,x-1,y-13,redpath);

    if ( d == bluepath or true )
        delete_draw(all_drawing);

        //d = get_id(type player);
        //x = d.x-1;
        //y= d.y-13;

        // get new direction
        //path_find
        x--;
        y-=13;

        num_points = path_find(1, file, path_map,2,tx-1,ty-13, &points, sizeof(points));
        x++;
        y+=13;

        IF (num_points>0)
          //  tx = points[0].x+1;
          //  ty = points[0].y+13;

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
        end
       debug;

    end



    frame;

end


end

