package com.nativedisplay.sample.xml.data

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET

interface DummyJsonApi {

    @GET("products")
    suspend fun getProducts(): ProductsResponse

    companion object {
        private const val BASE_URL = "https://dummyjson.com/"

        fun create(): DummyJsonApi {
            return Retrofit.Builder()
                .baseUrl(BASE_URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(DummyJsonApi::class.java)
        }
    }
}
