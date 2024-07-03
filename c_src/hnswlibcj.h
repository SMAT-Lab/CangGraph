#ifdef __cplusplus
extern "C" {
#endif

int init_index(int dim, const char *persist_directory);

int save_index(const char *persist_directory);

int addpoint(float *embeddings, int *labels, int elements, int dim, const char *persist_directory, bool update);

int deletepoint(int *delete_labels, int delete_elements, const char *persist_directory);

typedef struct {
   int   label;
   float dist;
} query_result;

query_result query(float *query_embeddings,int top_k);

int delete_all();

#ifdef __cplusplus
};
#endif


