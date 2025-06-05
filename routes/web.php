<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\TaskController;

// Public route: login
Route::get('/', function () {
    return view('login');
})->name('login');

// Public route: about (but only if you want it public)
Route::view('/about', 'about')->name('about');

// Authenticated routes
Route::middleware(['auth'])->group(function () {
    Route::get('/home', [TaskController::class, 'index'])->name('home');

    Route::resource('tasks', TaskController::class)->except(['index']);
    Route::post('tasks/{task}/complete', [TaskController::class, 'complete'])->name('tasks.complete');
    Route::resource('posts', PostController::class);
    Route::resource('projects', ProjectController::class);

    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';