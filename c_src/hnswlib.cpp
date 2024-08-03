#include <string.h>
#include <stdio.h>
#include <fstream>
#include <sys/stat.h>
#include <iostream>
#include <unistd.h>
#include "hnswlibcj.h"

#ifdef __cplusplus
extern "C" {
#endif

hnswlib::L2Space *space = nullptr;
hnswlib::HierarchicalNSW<float>* alg_hnsw = nullptr;

int total_elements_added = 0 ;

int init_index(int dim,const char *persist_directory){
    //初始化hnswlib

    //int dim Dimension of the elements
    space = new hnswlib::L2Space(dim);

    if (strlen(persist_directory) == 0)
    {
        int max_elements = 10000;   // Maximum number of elements, should be known beforehand
        int M = 16;                 // Tightly connected with internal dimensionality of the data
                                // strongly affects the memory consumption
        int ef_construction = 200;  // Controls index search speed/build speed tradeoff
        int seed = 100;

        alg_hnsw = new hnswlib::HierarchicalNSW<float>(space, max_elements, M, ef_construction,seed,true);
    }
    else
    {
        char hnsw_path[strlen(persist_directory)];
        strcpy(hnsw_path, persist_directory);
        strcat( hnsw_path, "/index/hnsw.bin");

        if (access(hnsw_path, F_OK) != 0)
        {            
            int max_elements = 10000;   // Maximum number of elements, should be known beforehand
            int M = 16;                 // Tightly connected with internal dimensionality of the data
                                        // strongly affects the memory consumption
            int ef_construction = 200;  // Controls index search speed/build speed tradeoff
            int seed = 100;

            alg_hnsw = new hnswlib::HierarchicalNSW<float>(space, max_elements, M, ef_construction,seed,true);
        }
        else
        {
            alg_hnsw = new hnswlib::HierarchicalNSW<float>(space, hnsw_path,false,0UL,true);
        }
    }

    return 0;
}

int save_index(const char *persist_directory){
    // Serialize index

    char hnsw_path[strlen(persist_directory)];
    strcpy(hnsw_path, persist_directory);
    strcat( hnsw_path, "/index");

    if (access(hnsw_path, F_OK) != 0)
    {
        if (access(persist_directory, F_OK) != 0)
        {
            int result_persist = mkdir(persist_directory, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
        }
        int result_hnsw = mkdir(hnsw_path, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    }

    strcat( hnsw_path, "/hnsw.bin");
    alg_hnsw->saveIndex(hnsw_path);

    return 0;
}

int addpoint(float *embeddings, int *labels, int elements, int dim, const char *persist_directory, bool update){
    // Add data to index

    //float* embeddings_data = embeddings[0];

    if (!update)
    {
        for (int i = 0; i < elements; i++) {
            alg_hnsw->addPoint(embeddings + i * dim, labels[i]);
            total_elements_added += 1;

            if (total_elements_added > alg_hnsw->max_elements_)
            {
                alg_hnsw->resizeIndex(total_elements_added);
            }  
        }
        
    }
    else
    {
        for (int i = 0; i < elements; i++) {
            alg_hnsw->addPoint(embeddings + i * dim, labels[i],true);
        }
    }

    if (strlen(persist_directory) != 0)
    {
        int save = save_index(persist_directory);
    }    

    return 0;
}

int deletepoint(int *delete_labels, int delete_elements,const char *persist_directory){

    for (int i = 0; i < delete_elements; i++) {
        alg_hnsw->markDelete(delete_labels[i]);
        total_elements_added -=1;
    }

    if (strlen(persist_directory) != 0)
    {
        int save = save_index(persist_directory);
    }   

    return 0;
}

query_result query(float *query_embeddings,int top_k){
    //Query the elements with query embeddings

    query_result res;

    std::priority_queue<std::pair<float, hnswlib::labeltype>> result = alg_hnsw->searchKnn(query_embeddings, top_k);
    res.dist = result.top().first;
    res.label = int(result.top().second);

    return res;
}

int delete_all(){
    delete alg_hnsw;
    return 0;
}

#ifdef __cplusplus
};
#endif

