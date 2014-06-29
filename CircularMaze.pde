/*
 The purpose of this class is to create a model of a circular maze.
 
 Rings are the spaces between adjacent concentric circles.
 These circles are increasing in radius at a constant rate.
 
 Rings are divided into rooms by lines extending from the center ring.
 The center ring itself is a room.
 
 Rings get further divided as the radius increases to power-of-2 multiples
 of the center radius.
 
 The indices of the rooms are:
 0 - the center
 1 to first ring size - start at some fixed angle, travel CCW
 (same for all other rings)
 
 Whether or not rooms are adjacent is determined using the weighted quick-union with path compression algorithm.
 */

class CircularMaze{
    
    //# of rings
    private int ringCount;
    //lines extending from center room
    private int centerLineCount;
    //# of rooms determined by ringCount and centerLineCount;
    private int roomCount;
    //for determining if rooms are connected;
    private WeightedQU weightedQU;
    //At this room index, the bits represent if the wall is open (unused bits/OCW/OCCW/O/I/CW/CCW)
    private byte[] adjacentRooms;
    
    /*
     myRingCount must be at least 1 (1 is just a circle)
     myCenterLineCount must be at least 1
     */
    public CircularMaze(int myRingCount, int myCenterLineCount){
        if(myRingCount<=0 || myCenterLineCount<=0)println("Invalid maze parameters.");
        
        ringCount=myRingCount;
        centerLineCount=myCenterLineCount;
        /*
         Ring#:
         1 has/is 1 room
         2 has myCenterLineCount rooms
         3-4 have 2 times as many
         5 6 7 8 have 4 times as many
         etc.
         So we need:
         1+centerLineCount*(1*1+2*2+4*4+8*8+...)
         */
        //TODO: look up a closed expression to determine roomCount
        
        //what if count is 1?
        int ringNumber=2;
        int roomsPerRing=1;//this is the same as the number of rooms with a common roomsPerRing
        while(true){
            //Should you add the group? i.e. if ringNumber is 2, add 1 for 2, if ringNumber is 8, add for 5 6 7 8
            if(ringNumber<=myRingCount){
                roomCount+=roomsPerRing*roomsPerRing;
                ringNumber*=2;
                roomsPerRing*=2;
            }else{
                roomCount+=(ringCount-ringNumber/2)*roomsPerRing;
                break;
            }
        }
        roomCount*=centerLineCount;
        roomCount+=1;//the center
        
        weightedQU=new WeightedQU(roomCount);
        adjacentRooms=new byte[roomCount];
        for(int i=0;i<roomCount;i++){
          if(GetRingNumber(i)+1==ringCount){
            for(;i<roomCount;i++){
              adjacentRooms[i]=2+16+32;//treat them as adjacent to their CW and outer
            }
          }else{
            adjacentRooms[i]=2+8+16+32;//treat them as adjacent to their CW and outer
          }
        }
        println("room count: "+roomCount);
    }
    
    /*
     When examining adjacent rooms, this class is used;
     i is the index. An index of -1 indicates the room is off limits.
     type is the type of adjacency:
     0 - CCW
     1 - CW
     2 - towards center
     3 - away from center
     4 - away from center and CCW
     5 - away from center and CW
     */
    public class IndexAndType{
        int i;
        int type;
        public IndexAndType(int myI, int myType){
            i=myI;
            type=myType;
        }
    }
    
    /*
     Given a room index calculate and return the adjacent room indices.
     */
    public ArrayList<IndexAndType> GetAdjacentIndices(int i){
        if(!(0<=i && i<roomCount))println("Invalid room index for GetAdjacentIndices (0<="+i+"<"+roomCount);
        
        ArrayList<IndexAndType> adjacentIndices=new ArrayList<IndexAndType>();
        
        if(i==0){
            //Case 1: the center
            
            for(int j=1;j<=centerLineCount;j++)
                adjacentIndices.add(new IndexAndType(j,3));
            return adjacentIndices;
        }
        
        //To get the CCW and CW rooms we need to know the starting index of their ring, and the ring size.
        ArrayList<Integer> NIS=GetRingNumberIndexSize(i);
        int ringNumber=(int)NIS.get(0);
        int ringStartIndex=(int)NIS.get(1);
        int ringSize=(int)NIS.get(2);
        //what else do we need?
        
        //CW
        if(ringStartIndex<=i-1)adjacentIndices.add(new IndexAndType(i-1,1));
        else adjacentIndices.add(new IndexAndType(ringStartIndex+ringSize-1,1));
        
        //CCW
        if(i+1<ringStartIndex+ringSize)adjacentIndices.add(new IndexAndType(i+1,0));
        else adjacentIndices.add(new IndexAndType(ringStartIndex,0));
        
        //Bottom (towards center)
        if(1<=i && i<=centerLineCount){
            adjacentIndices.add(new IndexAndType(0,2));
        }else{
            /*
             Ring size changes when entering outwards to a power of 2 ring number.
             If this ring is a power of 2, then the ring indices are not the same.
             */
            if(IsPowerOfTwo(ringNumber)){
                adjacentIndices.add(new IndexAndType(ringStartIndex-ringSize/2+(i-ringStartIndex)/2,2));
            }else{
                adjacentIndices.add(new IndexAndType(i-ringSize,2));
            }
        }
        
        //Top
        if(ringNumber+1<ringCount){
            if(IsPowerOfTwo(ringNumber+1)){
                adjacentIndices.add(new IndexAndType(2*(i-ringStartIndex)+ringStartIndex+ringSize,5));
                adjacentIndices.add(new IndexAndType(2*(i-ringStartIndex)+ringStartIndex+ringSize+1,4));
            }else{
                adjacentIndices.add(new IndexAndType(i+ringSize,3));
            }
        }else{
          adjacentIndices.add(new IndexAndType(-1,3));
        }
        
        return adjacentIndices;
    }
    
    /*
     Input a room number and this will connect that room to a random adjacent room,
     one that isn't already connected.
     Returns -1 if there are no more new adjacent rooms.
     */
    public int OpenRandomNewAdjacent(int i){
        
        ArrayList<IndexAndType> adjacentIndices=GetAdjacentIndices(i);
        
        //Get those which are not connected
        ArrayList<IndexAndType> potentialNewAdjacentIndices=new ArrayList<IndexAndType>();
        for(int n=0;n<adjacentIndices.size();n++){
            int j=(int)adjacentIndices.get(n).i;
            if(j!=-1 && !weightedQU.connected(i,j))
                potentialNewAdjacentIndices.add(adjacentIndices.get(n));
        }
        
        if(potentialNewAdjacentIndices.size()==0)return -1;
        
        int randomIndex=(int)random((float)potentialNewAdjacentIndices.size());
        
        IndexAndType newAdjacent=potentialNewAdjacentIndices.get(randomIndex);
        
        int newAdjacentIndex=(int)(newAdjacent.i);
        weightedQU.union(0,newAdjacentIndex);
        /*
        TODO:
        For the purposes of drawing the maze, we really only need the inner and CCW relationships (and outer for outer ring)
        i.e. we treat them as adjacent to their CW, and outer
        */
       
        switch(newAdjacent.type){
          case 0:
          adjacentRooms[i]|=1;
          //adjacentRooms[newAdjacentIndex]|=2;
          break;
          case 1:
          //adjacentRooms[i]|=2;
          adjacentRooms[newAdjacentIndex]|=1;
          break;
          case 2:
          adjacentRooms[i]|=4;
          //adjacentRooms[newAdjacentIndex]|=2;3 4 5
          break;
          case 3:
          //adjacentRooms[i]|=8;
          adjacentRooms[newAdjacentIndex]|=4;
          break;
          case 4:
          //adjacentRooms[i]|=16;
          adjacentRooms[newAdjacentIndex]|=4;
          break;
          case 5:
          //adjacentRooms[i]|=32;
          adjacentRooms[newAdjacentIndex]|=4;
          break;
        }
        return newAdjacent.i;
    }
    
    private boolean IsPowerOfTwo(int i){
        return (i>0 && (i&(i-1))==0);
    }
    
    /*
     Get the ring number (the center is zero)
     TODO: Implement a better/faster formula
     */
    private int GetRingNumber(int i){
        if(i==0)return 0;
        
        i--;//not in the first ring
        
        //We are about to check: is it in this ring number?
        int ringToCheck=1;
        //How many rooms are in the ring you are about to check?
        int ringSize=1;//multiples of centerLineCount, also acts as number of consecutive rings with same size
        while(true){
            for(int n=0;n<ringSize;n++){
                if(i<ringSize*centerLineCount)
                    return ringToCheck;
                
                i-=ringSize*centerLineCount;//not in that ring either
                ringToCheck++;
            }
            ringSize*=2;
        }
    }
    
    /*
     Does a bit more than the previous function;
     Given an index, return a size 3 ArrayList containing the ring number, ring starting index, and the ring size
     */
    private ArrayList<Integer> GetRingNumberIndexSize(int i){
        
        ArrayList<Integer> numIndSize=new ArrayList<Integer>();
        
        if(i==0){
            numIndSize.add(0);//number
            numIndSize.add(0);//index
            numIndSize.add(1);//size
            return numIndSize;
        }
        
        i--;//not in the first ring
        int indexOfNextRing=1;
        
        //We are about to check: is it in this ring number?
        int ringToCheck=1;
        //How many rooms are in the ring you are about to check?
        int ringSize=1;//multiples of centerLineCount, also acts as number of consecutive rings with same size
        while(true){
            for(int n=0;n<ringSize;n++){
                if(i<ringSize*centerLineCount){
                    numIndSize.add(ringToCheck);//number
                    numIndSize.add(indexOfNextRing);
                    numIndSize.add(ringSize*centerLineCount);//size
                    return numIndSize;
                }
                
                i-=ringSize*centerLineCount;//not in that ring either
                indexOfNextRing+=ringSize*centerLineCount;
                ringToCheck++;
            }
            ringSize*=2;
        }
    }
    
    /*
     Basic drawing function for the maze
     */
    public void DrawMaze(float centerX, float centerY, float ringWidth){
        int roomsPerRing=1;
        int currentRingNumber=1;
        int roomToExamine=1;
        while(true){
            for(int i=0;i<roomsPerRing;i++){//iterate over groups of rings (same as roomsPerRing)
                int roomInThisRing=0;
                int totalRoomsPerRing=roomsPerRing*centerLineCount;
                float angle=2*PI/totalRoomsPerRing;
                for(int j=0;j<totalRoomsPerRing;j++){
                    if((adjacentRooms[roomToExamine]&1)!=1)
                    line(centerX+currentRingNumber*ringWidth*cos((roomInThisRing+1)*angle), centerY+currentRingNumber*ringWidth*sin((roomInThisRing+1)*angle),
                                         centerX+(currentRingNumber+1)*ringWidth*cos((roomInThisRing+1)*angle), centerY+(currentRingNumber+1)*ringWidth*sin((roomInThisRing+1)*angle));
                                  
                    if((adjacentRooms[roomToExamine]&2)!=2)
                    line(centerX+currentRingNumber*ringWidth*cos(roomInThisRing*angle), centerY+currentRingNumber*ringWidth*sin(roomInThisRing*angle),
                                         centerX+(currentRingNumber+1)*ringWidth*cos(roomInThisRing*angle), centerY+(currentRingNumber+1)*ringWidth*sin(roomInThisRing*angle));
                                         
                    if((adjacentRooms[roomToExamine]&4)!=4)
                    arc(centerX, centerY, currentRingNumber*ringWidth*2, currentRingNumber*ringWidth*2, roomInThisRing*angle, (roomInThisRing+1)*angle);
                    
                    if((adjacentRooms[roomToExamine]&8)!=8)
                    arc(centerX, centerY, (currentRingNumber+1)*ringWidth*2, (currentRingNumber+1)*ringWidth*2, (roomInThisRing)*angle, (roomInThisRing+1)*angle);
                    
                    if((adjacentRooms[roomToExamine]&16)!=16)
                    arc(centerX, centerY, (currentRingNumber+1)*ringWidth*2, (currentRingNumber+1)*ringWidth*2, (roomInThisRing+0.5)*angle, (roomInThisRing+1)*angle);
                    
                    if((adjacentRooms[roomToExamine]&32)!=32)
                    arc(centerX, centerY, (currentRingNumber+1)*ringWidth*2, (currentRingNumber+1)*ringWidth*2, roomInThisRing*angle, (roomInThisRing+0.5)*angle);

                    roomInThisRing++;
                    roomToExamine++;
                }
                //println(currentRingNumber+"/"+ringCount);
                currentRingNumber++;
                if(currentRingNumber==ringCount){
                    //println("Finished drawing");
                    return;
                }
            }
            roomsPerRing*=2;
        }
    }
}
