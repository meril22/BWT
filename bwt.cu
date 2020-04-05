#include "bwt.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <cuda.h>

int comp_size = 1;                      

int lex_compare(const void * a, const void * b)
{
    unsigned char *x1 = *(unsigned char**)a;
    unsigned char *x2 = *(unsigned char**)b;

    return memcmp(x1, x2, comp_size*sizeof(unsigned char));
}


int lex_compare_2(const void * a, const void * b)
{
    unsigned char *x1 = *(unsigned char**)a;
    unsigned char *x2 = *(unsigned char**)b;
    
    
    for (int tmp_size = comp_size; tmp_size > 0; tmp_size--){
        if(!(*x1 ^ *x2)){
            x1++;
            x2++;
        }
        else if(*x1 < *x2){
            return -1;
        }
        else{
            return 1;
        }
    }
    return 0;
}


void __global__ bwt_encode(unsigned char ** bwt_in, unsigned char ** bwt_out, int len)
{
    unsigned char ** ptr_rotations, *concat_input;                         
    ptr_rotations = (unsigned char**) malloc(len*sizeof(unsigned char*));
    concat_input = (unsigned char*)malloc(2*len*sizeof(unsigned char) + 1);
    memcpy(concat_input, *bwt_in, len*sizeof(unsigned char));
    memcpy(concat_input + len*sizeof(unsigned char), *bwt_in, len*sizeof(unsigned char));
    
    concat_input[2*len] = '\0';                                
                                                                
    int i;
    for(i = 0; i < len; i++){
        ptr_rotations[i] = &(concat_input[i]);
    }
    
    comp_size = len;                                            
    qsort(ptr_rotations, len, sizeof(unsigned char*), lex_compare);      
   
    for( i = 0; i < len ; i++){
        (*bwt_out)[i] = *(ptr_rotations[i] + (len-1)*sizeof(unsigned char));    
        if(ptr_rotations[i] == concat_input){                                   
            (*bwt_out)[len] = i/(256*256);                                      
            (*bwt_out)[len + 1] = (i%(256*256))/256;                            
            (*bwt_out)[len + 2] = (i%(256*256))%256;                            
        }
    }
    cudafree(concat_input);
    concat_input = NULL;

    cudafree(ptr_rotations);
    ptr_rotations = NULL;

    return;
}


